resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "hcloud_ssh_key" "k3s" {
  name       = var.cluster_name
  public_key = local.ssh_public_key
}

resource "hcloud_network" "k3s" {
  name     = var.cluster_name
  ip_range = local.network_ipv4_cidr
}

# We start from the end of the subnets cird array, 
# as we would have fewer control plane nodepools, than angent ones.
resource "hcloud_network_subnet" "control_plane" {
  count        = length(var.control_plane_nodepools)
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets[255 - count.index]
}

# Here we start at the beginning of the subnets cird array
resource "hcloud_network_subnet" "agent" {
  count        = length(var.agent_nodepools)
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets[count.index]
}

resource "hcloud_firewall" "k3s" {
  name = var.cluster_name

  dynamic "rule" {
    for_each = concat(local.base_firewall_rules, var.extra_firewall_rules)
    content {
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      port            = lookup(rule.value, "port", null)
      destination_ips = lookup(rule.value, "destination_ips", [])
      source_ips      = lookup(rule.value, "source_ips", [])
    }
  }
}

resource "hcloud_placement_group" "control_plane" {
  count = ceil(local.control_plane_count / 10)
  name  = "${var.cluster_name}-control-plane-${count.index + 1}"
  type  = "spread"
}

resource "hcloud_placement_group" "agent" {
  count = ceil(local.agent_count / 10)
  name  = "${var.cluster_name}-agent-${count.index + 1}"
  type  = "spread"
}

data "hcloud_load_balancer" "traefik" {
  count = local.using_klipper_lb ? 0 : var.traefik_enabled == false ? 0 : 1
  name  = "${var.cluster_name}-traefik"

  depends_on = [null_resource.kustomization]
}

resource "null_resource" "destroy_traefik_loadbalancer" {

  # this only gets triggered before total destruction of the cluster, but when the necessary elements to run the commands are still available
  triggers = {
    kustomization_id = null_resource.kustomization.id
    cluster_name     = var.cluster_name
  }

  # Important when issuing terraform destroy, otherwise the LB will not let the network get deleted
  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl -n kube-system delete service traefik --kubeconfig ${self.triggers.cluster_name}_kubeconfig.yaml"
    on_failure = continue
  }

  depends_on = [
    local_sensitive_file.kubeconfig,
    null_resource.control_planes[0],
    hcloud_network_subnet.control_plane,
    hcloud_network_subnet.agent,
    hcloud_placement_group.control_plane,
    hcloud_placement_group.agent,
    hcloud_network.k3s,
    hcloud_firewall.k3s,
    hcloud_ssh_key.k3s
  ]
}
