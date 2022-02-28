resource "hcloud_server" "server" {
  name = var.name

  image              = "ubuntu-20.04"
  rescue             = "linux64"
  server_type        = var.server_type
  location           = var.location
  ssh_keys           = var.ssh_keys
  firewall_ids       = var.firewall_ids
  placement_group_id = var.placement_group_id
  user_data          = data.template_cloudinit_config.config.rendered

  labels = var.labels

  # Prevent destroying the whole cluster if the user changes
  # any of the attributes that force to recreate the servers.
  lifecycle {
    ignore_changes = [
      location,
      ssh_keys,
      user_data,
    ]
  }

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = self.ipv4_address
  }

  # Install MicroOS
  provisioner "remote-exec" {
    inline = local.microOS_install_commands
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
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 3
      done
    EOT
  }

  provisioner "remote-exec" {
    inline = [
      # Disable automatic reboot (after transactional updates), and configure the reboot method as kured
      "set -ex",
      "rebootmgrctl set-strategy off",
      "echo 'REBOOT_METHOD=kured' > /etc/transactional-update.conf",
    ]
  }
}

resource "hcloud_server_network" "server" {
  ip        = var.private_ipv4
  server_id = hcloud_server.server.id
  subnet_id = var.ipv4_subnet_id
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/templates/userdata.yaml.tpl",
      {
        hostname          = var.name
        sshAuthorizedKeys = concat([local.ssh_public_key], var.additional_public_keys)
      }
    )
  }

  # Initialization script (runs at every reboot)
  part {
    content_type = "text/cloud-boothook"
    filename     = "boothook.sh"
    content = templatefile(
      "${path.module}/templates/boothook.sh.tpl",
      {
        hostname = var.name
      }
    )
  }
}
