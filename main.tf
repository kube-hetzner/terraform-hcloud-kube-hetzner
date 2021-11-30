resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "hcloud_ssh_key" "default" {
  name       = "K3S terraform module - Provisioning SSH key"
  public_key = local.ssh_public_key
}

resource "hcloud_network" "k3s" {
  name     = "k3s-net"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "k3s" {
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/16"
}

resource "hcloud_firewall" "k3s" {
  name = "k3s-firewall"

  # Internal cluster traffic, kube api server, kubelet metrics, cilium, etcd,
  # and Hetzner metadata service and cloud api
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
}

data "hcloud_image" "linux" {
  name = "ubuntu-20.04"
}

locals {
  first_control_plane_network_ip = cidrhost(hcloud_network.k3s.ip_range, 2)
  name_master                    = "k3s-control-plane-0"
  ssh_public_key                 = trimspace(file(var.public_key))
}

data "template_file" "master" {
  template = file("${path.module}/templates/master.tpl")

  vars = {
    name           = local.name_master
    ssh_public_key = local.ssh_public_key
    k3s_token      = random_password.k3s_token.result
    ip             = local.first_control_plane_network_ip
  }
}
