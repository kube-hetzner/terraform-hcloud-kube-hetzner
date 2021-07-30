resource "hcloud_server" "control_planes" {
  count = var.servers_num - 1
  name  = "k3s-control-plane-${count.index + 1}"

  image       = data.hcloud_image.linux.name
  server_type = local.control_plane_server_type
  location    = local.server_locations[count.index + 1][1]

  ssh_keys = [hcloud_ssh_key.default.id]

  labels = {
    provisioner = "terraform",
    engine      = "k3s",
    node_type   = "control-plane"
    k3s_upgrade = "true"
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
      "curl -sfL https://get.k3s.io | K3S_TOKEN=${random_password.k3s_cluster_secret.result} sh -s - server --server https://${local.first_control_plane_ip}:6443 ${var.k3s_extra_args}"
    ]

    connection {
      user        = "root"
      private_key = file(var.private_key)
      host        = self.ipv4_address
    }
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = cidrhost(hcloud_network.k3s.ip_range, 3 + count.index)
  }

  depends_on = [
    hcloud_server.first_control_plane,
    hcloud_network_subnet.k3s
  ]
}
