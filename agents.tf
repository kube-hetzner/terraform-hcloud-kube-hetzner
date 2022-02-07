resource "hcloud_server" "agents" {
  count = var.agents_num
  name  = "k3s-agent-${count.index}"

  image              = data.hcloud_image.linux.name
  rescue             = "linux64"
  server_type        = var.agent_server_type
  location           = var.location
  ssh_keys           = [hcloud_ssh_key.k3s.id]
  firewall_ids       = [hcloud_firewall.k3s.id]
  placement_group_id = hcloud_placement_group.k3s_placement_group.id


  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s",
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

  # Issue a reboot command
  provisioner "local-exec" {
    command = "ssh ${local.ssh_args} root@${self.ipv4_address} '(sleep 2; reboot)&'; sleep 3"
  }

  # Wait for MicroOS to reboot and be ready
  provisioner "local-exec" {
    command = <<-EOT
      until ssh ${local.ssh_args} -o ConnectTimeout=2 root@${self.ipv4_address} true 2> /dev/null
      do
        echo Waiting for ssh to be ready...
        sleep 2
      done
    EOT
  }

  # Generating k3s server config file
  provisioner "file" {
    content = yamlencode({
      node-name     = self.name
      server        = "https://${local.first_control_plane_network_ip}:6443"
      kubelet-arg   = "cloud-provider=external"
      flannel-iface = "eth1"
      node-ip       = local.first_control_plane_network_ip
      token         = random_password.k3s_token.result
    })
    destination = "/etc/rancher/k3s/config.yaml"

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  # Run the agent
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      # first we disable automatic reboot (after transactional updates), and configure the reboot method as kured
      "rebootmgrctl set-strategy off && echo 'REBOOT_METHOD=kured' > /etc/transactional-update.conf",
      # then turn on k3s and join the cluster
      "systemctl --now enable k3s-agent",
    ]

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = cidrhost(hcloud_network.k3s.ip_range, 2 + var.servers_num + count.index)
  }

  depends_on = [
    hcloud_server.first_control_plane,
    hcloud_network_subnet.k3s
  ]
}
