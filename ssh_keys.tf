resource "null_resource" "add_ssh_keys" {
  for_each = toset(concat([hcloud_server.first_control_plane.ipv4_address], hcloud_server.control_planes.*.ipv4_address, hcloud_server.agents.*.ipv4_address))

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = each.value
  }

  provisioner "remote-exec" {
    inline = [ 
      "echo '${join("\n", concat(var.additional_public_keys, [local.ssh_public_key]))}' > /root/.ssh/authorized_keys",
    ]
  }

  depends_on = [
    "hcloud_server.first_control_plane",
    "hcloud_server.control_planes",
    "hcloud_server.agents"
  ]

  triggers = {
    always_run = "${join("\n", concat(var.additional_public_keys, [local.ssh_public_key]))}"
  }
}
