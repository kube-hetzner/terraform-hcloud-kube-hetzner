resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

data "hcloud_image" "microos_x86_snapshot" {
  with_selector     = "microos-snapshot=yes"
  with_architecture = "x86"
  most_recent       = true
}

data "hcloud_image" "microos_aarch64_snapshot" {
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
  name     = var.cluster_name
  ip_range = var.network_ipv4_cidr
  labels   = local.labels
}

# We start from the end of the subnets cidr array,
# as we would have fewer control plane nodepools, than agent ones.
resource "hcloud_network_subnet" "control_plane" {
  count        = length(var.control_plane_nodepools)
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets[255 - count.index]
}

# Here we start at the beginning of the subnets cidr array
resource "hcloud_network_subnet" "agent" {
  count        = length(var.agent_nodepools)
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets[count.index]
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

resource "hcloud_placement_group" "control_plane" {
  count  = ceil(local.control_plane_count / 10)
  name   = "${var.cluster_name}-control-plane-${count.index + 1}"
  labels = local.labels
  type   = "spread"
}

resource "hcloud_placement_group" "agent" {
  count  = ceil(local.agent_count / 10)
  name   = "${var.cluster_name}-agent-${count.index + 1}"
  labels = local.labels
  type   = "spread"
}
