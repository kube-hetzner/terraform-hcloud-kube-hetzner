resource "hcloud_server" "agents" {
  count = var.agents_num
  name  = "k3s-agent-${count.index}"

  image        = data.hcloud_image.linux.name
  rescue       = "linux64"
  server_type  = var.agent_server_type
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k3s.id]


  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s",
    "k3s_upgrade" = "true"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/agent.tpl", {
      name           = self.name
      ssh_public_key = local.ssh_public_key
      k3s_token      = random_password.k3s_token.result
      master_ip      = local.first_control_plane_network_ip
      node_ip        = cidrhost(hcloud_network.k3s.ip_range, 2 + var.servers_num + count.index)
    })
    destination = "/tmp/config.yaml"

    connection {
      user        = "root"
      private_key = file(var.private_key)
      host        = self.ipv4_address
    }
  }


  provisioner "remote-exec" {
    inline = local.k3os_install_commands

    connection {
      user        = "root"
      private_key = file(var.private_key)
      host        = self.ipv4_address
    }
  }

  provisioner "local-exec" {
    command = "sleep 60 && ping ${self.ipv4_address} | grep --line-buffered 'bytes from' | head -1 && sleep 100"
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
