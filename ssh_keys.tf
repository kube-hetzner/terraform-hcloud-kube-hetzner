resource "null_resource" "add_ssh_keys_servers" {
  count = var.servers_num - 1

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = hcloud_server.control_planes[count.index].ipv4_address

  }

  provisioner "remote-exec" {
    inline = [
      "echo '${join("\n", local.ssh_public_keys)}' > /root/.ssh/authorized_keys",
    ]
  }

  depends_on = [
    hcloud_server.control_planes
  ]

  triggers = {
    always_run = "${join("\n", local.ssh_public_keys)}"
  }
}

resource "null_resource" "add_ssh_keys_first_control_plane" {
  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = hcloud_server.first_control_plane.ipv4_address

  }

  provisioner "remote-exec" {
    inline = [
      "echo '${join("\n", local.ssh_public_keys)}' > /root/.ssh/authorized_keys",
    ]
  }

  depends_on = [
    hcloud_server.first_control_plane
  ]

  triggers = {
    always_run = "${join("\n", local.ssh_public_keys)}"
  }
}

resource "null_resource" "add_ssh_keys_agents" {
  count = var.agents_num

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = hcloud_server.agents[count.index].ipv4_address

  }

  provisioner "remote-exec" {
    inline = [
      "echo '${join("\n", local.ssh_public_keys)}' > /root/.ssh/authorized_keys",
    ]
  }

  depends_on = [
    hcloud_server.agents
  ]

  triggers = {
    always_run = "${join("\n", local.ssh_public_keys)}"
  }
}
