variable "hcloud_token" {
  description = "Hetzner API tokey"
  type        = string
}

variable "public_key" {
  description = "SSH public Key."
  type        = string
}

variable "private_key" {
  description = "SSH private Key."
  type        = string
}

variable "location" {
  description = "Default server location"
  type        = string
}

variable "control_plane_server_type" {
  description = "Default control plane server type"
  type        = string
}

variable "agent_server_type" {
  description = "Default agent server type"
  type        = string
}

variable "lb_server_type" {
  description = "Default load balancer server type"
  type        = string
}

variable "servers_num" {
  description = "Number of control plane nodes."
  type        = number
}

variable "agents_num" {
  description = "Number of agent nodes."
  type        = number
}

provider "hcloud" {
  token = var.hcloud_token
}

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


locals {
  first_control_plane_network_ip = cidrhost(hcloud_network.k3s.ip_range, 2)
  ssh_public_key                 = trimspace(file(var.public_key))
  hcloud_image_name              = "ubuntu-20.04"

  k3os_install_commands = [
    "apt install -y grub-efi grub-pc-bin mtools xorriso",
    "latest=$(curl -s https://api.github.com/repos/rancher/k3os/releases | jq '.[0].tag_name')",
    "curl -Lo ./install.sh https://raw.githubusercontent.com/rancher/k3os/$(echo $latest | xargs)/install.sh",
    "chmod +x ./install.sh",
    "./install.sh --config /tmp/config.yaml /dev/sda https://github.com/rancher/k3os/releases/download/$(echo $latest | xargs)/k3os-amd64.iso",
    "shutdown -r +1",
    "sleep 3",
    "exit 0"
  ]
}

data "hcloud_image" "linux" {
  name = local.hcloud_image_name
}

resource "local_file" "traefik_config" {
  content = templatefile("${path.module}/templates/traefik_config.yaml.tpl", {
    lb_server_type = var.lb_server_type
    location       = var.location
  })
  filename = "${path.module}/templates/rendered/traefik_config.yaml"
}
