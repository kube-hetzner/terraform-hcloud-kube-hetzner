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
    ip         = try(var.ip, null)
  }

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = self.ipv4_address
  }

  provisioner "file" {
    content     = local.ignition_config
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
        sleep 3
      done
    EOT
  }

  provisioner "remote-exec" {
    inline = [
      # Disable automatic reboot (after transactional updates), and configure the reboot method as kured
      "rebootmgrctl set-strategy off && echo 'REBOOT_METHOD=kured' > /etc/transactional-update.conf",
      # set the hostname
      <<-EOT
      hostnamectl set-hostname ${self.name}
      sed -e 's#NETCONFIG_NIS_SETDOMAINNAME="yes"#NETCONFIG_NIS_SETDOMAINNAME="no"#g' /etc/sysconfig/network/config > /dev/null
      EOT
    ]
  }
}
