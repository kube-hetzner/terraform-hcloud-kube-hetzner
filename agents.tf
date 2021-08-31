resource "hcloud_server" "agents" {
  count = var.agents_num
  name  = "k3s-agent-${count.index}"

  image        = data.hcloud_image.linux.name
  server_type  = var.agent_server_type
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k3s.id]


  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s",
    "k3s_upgrade" = "true"
  }

  user_data = data.template_cloudinit_config.init_cfg.rendered

  provisioner "remote-exec" {
    inline = var.initial_commands

    connection {
      user        = "root"
      private_key = file(var.private_key)
      host        = self.ipv4_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_TOKEN=${random_password.k3s_cluster_secret.result} sh -s - agent --server https://${local.first_control_plane_network_ip}:6443 --node-ip=${cidrhost(hcloud_network.k3s.ip_range, 2 + var.servers_num + count.index)} ${var.k3s_agent_flags}"
    ]

    connection {
      user        = "root"
      private_key = file(var.private_key)
      host        = self.ipv4_address
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
