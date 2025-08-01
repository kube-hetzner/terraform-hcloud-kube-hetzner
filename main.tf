resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

data "hcloud_image" "microos_x86_snapshot" {
  with_selector     = "microos-snapshot=yes"
  with_architecture = "x86"
  most_recent       = true
}

data "hcloud_image" "microos_arm_snapshot" {
  with_selector     = "microos-snapshot=yes"
  with_architecture = "arm"
  most_recent       = true
}

resource "hcloud_ssh_key" "k3s" {
  count      = var.hcloud_ssh_key_id == null ? 1 : 0
  name       = var.cluster_name
  public_key = var.ssh_public_key
  labels     = local.labels
}

resource "hcloud_network" "k3s" {
  count    = local.use_existing_network ? 0 : 1
  name     = var.cluster_name
  ip_range = var.network_ipv4_cidr
  labels   = local.labels
}

data "hcloud_network" "k3s" {
  id = local.use_existing_network ? var.existing_network_id[0] : hcloud_network.k3s[0].id
}


resource "hcloud_network_subnet" "control_plane" {
  count        = length(var.control_plane_nodepools)
  network_id   = data.hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets_control_plane_pools[count.index]
}

resource "hcloud_network_subnet" "agent" {
  count        = length(var.agent_nodepools)
  network_id   = data.hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets_agent_pools[count.index]
}

resource "hcloud_network_subnet" "peripherals" {
  network_id   = data.hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnet_peripherals
}


resource "hcloud_firewall" "k3s" {
  name   = var.cluster_name
  labels = local.labels

  dynamic "rule" {
    for_each = local.firewall_rules_list
    content {
      description     = rule.value.description
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      port            = lookup(rule.value, "port", null)
      destination_ips = lookup(rule.value, "destination_ips", [])
      source_ips      = lookup(rule.value, "source_ips", [])
    }
  }
}

