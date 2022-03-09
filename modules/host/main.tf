resource "random_pet" "server" {
  length = 1
  keepers = {
    # We re-create the id (and server) whenever one of those attributes
    # changes.
    name                   = var.name
    public_key             = var.public_key
    additional_public_keys = join(",", var.additional_public_keys)
    placement_group_id     = var.placement_group_id
    private_ipv4           = var.private_ipv4
  }
}

resource "hcloud_server" "server" {
  name = local.name

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
    inline = [
      "set -ex",
      "apt-get update",
      "apt-get install -y aria2",
      "aria2c --follow-metalink=mem https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2.meta4",
      "qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda",
    ]
  }

  # Issue a reboot command and wait for MicroOS to reboot and be ready
  provisioner "local-exec" {
    command = <<-EOT
      ssh ${local.ssh_args} root@${self.ipv4_address} '(sleep 2; reboot)&'; sleep 3
      until ssh ${local.ssh_args} -o ConnectTimeout=2 root@${self.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 3
      done
    EOT
  }

  # Install k3s-selinux (compatible version)
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "transactional-update pkg install -y k3s-selinux"
    ]
  }

  # Issue a reboot command and wait for MicroOS to reboot and be ready
  provisioner "local-exec" {
    command = <<-EOT
      ssh ${local.ssh_args} root@${self.ipv4_address} '(sleep 2; reboot)&'; sleep 3
      until ssh ${local.ssh_args} -o ConnectTimeout=2 root@${self.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 3
      done
    EOT
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
        hostname          = local.name
        sshAuthorizedKeys = concat([local.ssh_public_key], var.additional_public_keys)
      }
    )
  }
}
