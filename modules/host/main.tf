resource "hcloud_server" "server" {
  name = var.name

  image              = "ubuntu-20.04"
  rescue             = "linux64"
  server_type        = var.server_type
  location           = var.location
  ssh_keys           = var.ssh_keys
  firewall_ids       = var.firewall_ids
  placement_group_id = var.placement_group_id


  labels = var.labels

  network {
    network_id = var.network_id
    ip         = var.ip
  }

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = self.ipv4_address
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/config.ign.tpl", {
      name           = self.name
      ssh_public_key = local.ssh_public_key
    })
    destination = "/root/config.ign"
  }

  # Combustion script file to install k3s-selinux
  provisioner "file" {
    content     = local.combustion_script
    destination = "/root/script"
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
        sleep 2
      done
    EOT
  }

  # Run the agent
  provisioner "remote-exec" {
    inline = [
      # set the hostname in a persistent fashion
      "hostnamectl set-hostname ${self.name}",
      # Disable automatic reboot (after transactional updates), and configure the reboot method as kured
      "rebootmgrctl set-strategy off && echo 'REBOOT_METHOD=kured' > /etc/transactional-update.conf"
    ]
  }
}
