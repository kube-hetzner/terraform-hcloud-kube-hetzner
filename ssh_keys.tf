resource "null_resource" "add_ssh_keys" {
  for_each = toset(local.all_server_ips)

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = each.value
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${join("\n", local.ssh_public_keys)}' > /root/.ssh/authorized_keys",
    ]
  }

  depends_on = [
    "hcloud_server.first_control_plane",
    "hcloud_server.control_planes",
    "hcloud_server.agents"
  ]

  triggers = {
    always_run = "${join("\n", local.ssh_public_keys)}"
  }
}
