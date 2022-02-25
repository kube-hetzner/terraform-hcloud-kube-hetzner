resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "hcloud_ssh_key" "k3s" {
  name       = "k3s"
  public_key = local.ssh_public_key
}

resource "hcloud_network" "k3s" {
  name     = "k3s"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "k3s" {
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = "10.0.0.0/16"
}

resource "hcloud_firewall" "k3s" {
  name = "k3s"

  # Allowing internal cluster traffic and Hetzner metadata service and cloud API IPs
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "any"
    source_ips = [
      "127.0.0.1/32",
      "10.0.0.0/8",
      "169.254.169.254/32",
      "213.239.246.1/32"
    ]
  }
  rule {
    direction = "in"
    protocol  = "udp"
    port      = "any"
    source_ips = [
      "127.0.0.1/32",
      "10.0.0.0/8",
      "169.254.169.254/32",
      "213.239.246.1/32"
    ]
  }
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "127.0.0.1/32",
      "10.0.0.0/8",
      "169.254.169.254/32",
      "213.239.246.1/32"
    ]
  }

  # Allow all traffic to the kube api server
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = [
      "0.0.0.0/0"
    ]
  }

  # Allow all traffic to the ssh port
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0"
    ]
  }

  # Allow ping on ipv4
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0"
    ]
  }

  # Allow basic out traffic
  # ICMP to ping outside services
  rule {
    direction = "out"
    protocol  = "icmp"
    destination_ips = [
      "0.0.0.0/0"
    ]
  }

  # DNS
  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "53"
    destination_ips = [
      "0.0.0.0/0"
    ]
  }
  rule {
    direction = "out"
    protocol  = "udp"
    port      = "53"
    destination_ips = [
      "0.0.0.0/0"
    ]
  }

  # HTTP(s)
  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "80"
    destination_ips = [
      "0.0.0.0/0"
    ]
  }
  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "443"
    destination_ips = [
      "0.0.0.0/0"
    ]
  }

  #NTP
  rule {
    direction = "out"
    protocol  = "udp"
    port      = "123"
    destination_ips = [
      "0.0.0.0/0"
    ]
  }

}

resource "hcloud_placement_group" "k3s" {
  name = "k3s"
  type = "spread"
  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }
}

data "hcloud_load_balancer" "traefik" {
  name = "traefik"

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
    local_file.kubeconfig,
    null_resource.control_planes[0],
    hcloud_network_subnet.k3s,
    hcloud_network.k3s,
    hcloud_firewall.k3s,
    hcloud_placement_group.k3s,
    hcloud_ssh_key.k3s
  ]
}
