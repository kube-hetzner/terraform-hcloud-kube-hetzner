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

resource "local_file" "hetzner_ccm_config" {
  content = templatefile("${path.module}/templates/hetzner_ccm.yaml.tpl", {
    ccm_version = var.hetzner_ccm_version != null ? var.hetzner_ccm_version : data.github_release.hetzner_ccm.release_tag
    patch_name  = var.hetzner_ccm_containers_latest ? "patch_latest" : "patch"
  })
  filename             = "${path.module}/hetzner/ccm/kustomization.yaml"
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "local_file" "hetzner_csi_config" {
  content = templatefile("${path.module}/templates/hetzner_csi.yaml.tpl", {
    csi_version = var.hetzner_csi_version != null ? var.hetzner_csi_version : data.github_release.hetzner_csi.release_tag
    patch_name  = var.hetzner_csi_containers_latest ? "patch_latest" : ""
  })
  filename             = "${path.module}/hetzner/csi/kustomization.yaml"
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "local_file" "traefik_config" {
  content = templatefile("${path.module}/templates/traefik_config.yaml.tpl", {
    lb_disable_ipv6 = var.lb_disable_ipv6
    lb_server_type  = var.lb_server_type
    location        = var.location
  })
  filename             = "${path.module}/templates/rendered/traefik_config.yaml"
  file_permission      = "0644"
  directory_permission = "0755"
}


resource "hcloud_placement_group" "k3s_placement_group" {
  name = "k3s-placement-group"
  type = "spread"
  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }
}
