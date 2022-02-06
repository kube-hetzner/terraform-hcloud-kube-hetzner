resource "hcloud_server" "first_control_plane" {
  name = "k3s-control-plane-0"

  image              = data.hcloud_image.linux.name
  rescue             = "linux64"
  server_type        = var.control_plane_server_type
  location           = var.location
  ssh_keys           = [hcloud_ssh_key.k3s.id]
  firewall_ids       = [hcloud_firewall.k3s.id]
  placement_group_id = hcloud_placement_group.k3s_placement_group.id

  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/config.ign.tpl", {
      name           = self.name
      ssh_public_key = local.ssh_public_key
    })
    destination = "/root/config.ign"

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  # Install MicroOS
  provisioner "remote-exec" {
    inline = local.MicroOS_install_commands

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  # Wait for MicroOS to reboot and be ready
  provisioner "local-exec" {
    command = "sleep 60 && ping ${self.ipv4_address} | grep --line-buffered 'bytes from' | head -1 && sleep 30"
  }

  # Generating k3s master config file
  provisioner "file" {
    content = templatefile("${path.module}/templates/master_config.yaml.tpl", {
      node_ip   = local.first_control_plane_network_ip
      token     = random_password.k3s_token.result
      node_name = self.name
    })
    destination = "/etc/rancher/k3s/config.yaml"

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  provisioner "file" {
    content     = local.post_install_kustomization
    destination = "/tmp/kustomization.yaml"

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  provisioner "file" {
    content     = local.traefik_config
    destination = "/tmp/traefik.yaml"

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

 # Run the first control plane
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      # first we disable automatic reboot (after transactional updates), and configure the reboot method as kured
      "rebootmgrctl set-strategy off && echo 'REBOOT_METHOD=kured' > /etc/transactional-update.conf",
      # then we initiate the cluster
      "systemctl --now enable k3s-server",
    ]

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  # Install Hetzner CCM and CSI, traefik and other kustomizations
  provisioner "remote-exec" {
    inline = [
      "while ! test -f /etc/rancher/k3s/k3s.yaml; do sleep 1; done",
      "kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=${hcloud_network.k3s.name}",
      "kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token}",
      "kubectl apply -k /tmp/",
      "kubectl apply -f /tmp/traefik.yaml",
      "rm /tmp/traefik.yaml /tmp/kustomization.yaml"
    ]

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
      # by default, the inline commands above would be written to a path like
      # /tmp/terraform_137284109.sh, but /tmp is mounted with noexec in k3os,
      # so we change this path.
      script_path = "/home/rancher/post-install.bash"
    }
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = local.first_control_plane_network_ip
  }

  depends_on = [
    hcloud_network_subnet.k3s,
    hcloud_firewall.k3s
  ]
}
