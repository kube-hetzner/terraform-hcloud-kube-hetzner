resource "random_password" "k3s_cluster_secret" {
  length  = 48
  special = false
}

resource "hcloud_ssh_key" "default" {
  name       = "K3S terraform module - Provisioning SSH key"
  public_key = file(var.public_key)
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
}

data "hcloud_image" "linux" {
  name = "fedora-34"
}

data "template_file" "init_cfg" {
  template = file("init.cfg")
}

# Render a multi-part cloud-init config making use of the part
# above, and other source files
data "template_cloudinit_config" "init_cfg" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.init_cfg.rendered
  }
}

data "template_file" "ccm_manifest" {
  template = file("${path.module}/manifests/hcloud-ccm-net.yaml")
}

data "template_file" "upgrade_plan" {
  template = file("${path.module}/manifests/upgrade/plan.yaml")
}

locals {
  first_control_plane_network_ip = cidrhost(hcloud_network.k3s.ip_range, 2)
}
