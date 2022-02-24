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

resource "null_resource" "destroy_lb" {
  triggers = {
    token = random_password.k3s_token.result
  }

  # Important when issuing terraform destroy, otherwise the LB will not let the network get deleted
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      hcloud load-balancer delete traefik
      hcloud network delete k3s
    EOT

    on_failure = continue
  }
}
