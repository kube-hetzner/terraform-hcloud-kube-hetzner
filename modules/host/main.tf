resource "random_string" "server" {
  length  = 3
  lower   = true
  special = false
  numeric = false
  upper   = false

  keepers = {
    # We re-create the apart of the name changes.
    name = var.name
  }
}

resource "random_string" "identity_file" {
  length  = 20
  lower   = true
  special = false
  numeric = true
  upper   = false
}

resource "hcloud_server" "server" {
  name               = local.name
  image              = "ubuntu-20.04"
  rescue             = "linux64"
  server_type        = var.server_type
  location           = var.location
  ssh_keys           = var.ssh_keys
  firewall_ids       = var.firewall_ids
  placement_group_id = var.placement_group_id
  user_data          = data.cloudinit_config.config.rendered

  labels = var.labels

  # Prevent destroying the whole cluster if the user changes
  # any of the attributes that force to recreate the servers.
  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      location,
      ssh_keys,
      user_data,
    ]
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = self.ipv4_address
    port           = var.ssh_port
  }

  # Prepare ssh identity file
  provisioner "local-exec" {
    command = <<-EOT
      install -b -m 600 /dev/null /tmp/${random_string.identity_file.id}
      echo "${local.ssh_client_identity}" > /tmp/${random_string.identity_file.id}
    EOT
  }

  # Install MicroOS
  provisioner "remote-exec" {
    connection {
      user           = "root"
      private_key    = var.ssh_private_key
      agent_identity = local.ssh_agent_identity
      host           = self.ipv4_address

      # We cannot use different ports here as this runs inside Hetzner Rescue image and thus uses the
      # standard 22 TCP port.
      port = 22
    }

    inline = [
      "set -ex",
      "apt-get update",
      "apt-get install -y aria2",
      "aria2c --follow-metalink=mem https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2.meta4",
      "qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda",
    ]
  }

  # Issue a reboot command.
  provisioner "local-exec" {
    command = <<-EOT
      ssh ${local.ssh_args} -i /tmp/${random_string.identity_file.id} root@${self.ipv4_address} '(sleep 2; reboot)&'; sleep 3
    EOT
  }

  # Wait for MicroOS to reboot and be ready.
  provisioner "local-exec" {
    command = <<-EOT
      until ssh ${local.ssh_args} -i /tmp/${random_string.identity_file.id} -o ConnectTimeout=2 -p ${var.ssh_port} root@${self.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 3
      done
    EOT
  }

  # Install k3s-selinux (compatible version) and open-iscsi
  provisioner "remote-exec" {
    connection {
      user           = "root"
      private_key    = var.ssh_private_key
      agent_identity = local.ssh_agent_identity
      host           = self.ipv4_address
      port           = var.ssh_port
    }

    inline = [<<-EOT
      set -ex
      transactional-update shell <<< "zypper --gpg-auto-import-keys install -y ${local.needed_packages}"
      EOT
    ]
  }

  # Issue a reboot command.
  provisioner "local-exec" {
    command = <<-EOT
      ssh ${local.ssh_args} -i /tmp/${random_string.identity_file.id} -p ${var.ssh_port} root@${self.ipv4_address} '(sleep 3; reboot)&'; sleep 3
    EOT
  }

  # Wait for MicroOS to reboot and be ready
  provisioner "local-exec" {
    command = <<-EOT
      until ssh ${local.ssh_args} -i /tmp/${random_string.identity_file.id} -o ConnectTimeout=2 -p ${var.ssh_port} root@${self.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 3
      done
    EOT
  }

  # Cleanup ssh identity file 
  provisioner "local-exec" {
    command = <<-EOT
      rm /tmp/${random_string.identity_file.id}
    EOT
  }

  # Enable open-iscsi
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -ex
      if [[ $(systemctl list-units --all -t service --full --no-legend "iscsid.service" | sed 's/^\s*//g' | cut -f1 -d' ') == iscsid.service ]]; then
        systemctl enable --now iscsid
      fi
      EOT
    ]
  }
}

resource "hcloud_rdns" "server" {
  count      = var.base_domain != "" ? 1 : 0
  server_id  = hcloud_server.server.id
  ip_address = hcloud_server.server.ipv4_address
  dns_ptr    = format("%s.%s", local.name, var.base_domain)
}

resource "hcloud_server_network" "server" {
  ip        = var.private_ipv4
  server_id = hcloud_server.server.id
  subnet_id = var.ipv4_subnet_id
}

data "cloudinit_config" "config" {
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
        sshPort           = var.ssh_port
        sshAuthorizedKeys = concat([var.ssh_public_key], var.ssh_additional_public_keys)
        dnsServers        = var.dns_servers
      }
    )
  }
}
