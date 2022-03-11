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
  ip_range = var.network_ipv4_range
}

# This is the default subnet to be used by the load balancer.
resource "hcloud_network_subnet" "default" {
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "subnet" {
  for_each     = var.network_ipv4_subnets
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = each.value

  depends_on = [hcloud_network_subnet.default]
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

resource "hcloud_placement_group" "k3s" {
  name = var.cluster_name
  type = "spread"
  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }
}

data "hcloud_load_balancer" "traefik" {
  count = local.is_single_node_cluster ? 0 : var.traefik_enabled == false ? 0 : 1
  name  = "${var.cluster_name}-traefik"

  depends_on = [null_resource.kustomization]
}

resource "null_resource" "destroy_traefik_loadbalancer" {
  # this only gets triggered before total destruction of the cluster, but when the necessary elements to run the commands are still available
  triggers = {
    kustomization_id = null_resource.kustomization.id
  }

  # Important when issuing terraform destroy, otherwise the LB will not let the network get deleted
  provisioner "local-exec" {
    when       = destroy
    command    = <<-EOT
      kubectl -n kube-system delete service traefik --kubeconfig ${path.module}/kubeconfig.yaml
    EOT
    on_failure = continue
  }

  depends_on = [
    local_sensitive_file.kubeconfig,
    null_resource.control_planes[0],
    hcloud_network_subnet.subnet,
    hcloud_network.k3s,
    hcloud_firewall.k3s,
    hcloud_placement_group.k3s,
    hcloud_ssh_key.k3s
  ]
}
