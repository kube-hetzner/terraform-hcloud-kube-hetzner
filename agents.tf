resource "hcloud_server" "agents" {
  count = var.agents_num
  name  = "k3s-agent-${count.index}"

  image              = data.hcloud_image.linux.name
  rescue             = "linux64"
  server_type        = var.agent_server_type
  location           = var.location
  ssh_keys           = [hcloud_ssh_key.k3s.id]
  firewall_ids       = [hcloud_firewall.k3s.id]
  placement_group_id = hcloud_placement_group.k3s.id


  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s",
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

  # Install MicroOS
  provisioner "remote-exec" {
    inline = local.microOS_install_commands
  }

  # Issue a reboot command and wait for the node to reboot
  provisioner "local-exec" {
    command = "ssh ${local.ssh_args} root@${self.ipv4_address} '(sleep 2; reboot)&'; sleep 3"
  }
  provisioner "local-exec" {
    command = <<-EOT
      until ssh ${local.ssh_args} -o ConnectTimeout=2 root@${self.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 2
      done
    EOT
  }

  # Generating k3s agent config file
  provisioner "file" {
    content = yamlencode({
      node-name     = self.name
      server        = "https://${local.first_control_plane_network_ip}:6443"
      token         = random_password.k3s_token.result
      kubelet-arg   = "cloud-provider=external"
      flannel-iface = "eth1"
      node-ip       = cidrhost(hcloud_network_subnet.k3s.ip_range, 513 + count.index)
      node-label    = var.automatically_upgrade_k3s ? ["k3s-upgrade=true"] : []
    })
    destination = "/tmp/config.yaml"
  }

  # Install k3s agent
  provisioner "remote-exec" {
    inline = local.install_k3s_agent
  }

  # Issue a reboot command and wait for the node to reboot
  provisioner "local-exec" {
    command = "ssh ${local.ssh_args} root@${self.ipv4_address} '(sleep 2; reboot)&'; sleep 3"
  }
  provisioner "local-exec" {
    command = <<-EOT
      until ssh ${local.ssh_args} -o ConnectTimeout=2 root@${self.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 2
      done
    EOT
  }

  # Upon reboot verify that k3s agent starts correctly
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      timeout 120 bash <<EOF
        until systemctl status k3s-agent > /dev/null; do
          echo "Waiting for the k3s agent to start..."
          sleep 2
        done
      EOF
      EOT
    ]
  }


  network {
    network_id = hcloud_network.k3s.id
    ip         = cidrhost(hcloud_network_subnet.k3s.ip_range, 513 + count.index)
  }

  depends_on = [
    hcloud_server.first_control_plane,
    hcloud_network_subnet.k3s
  ]
}
