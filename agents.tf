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
    inline = local.MicroOS_install_commands
  }

  # Issue a reboot command
  provisioner "remote-exec" {
    inline = [
      "sleep 2",
      "reboot"
    ]
    # reboot doesn't return a proper exit code, so we have to trust that it works
    on_failure = continue
  }

  # Wait for MicroOS to reboot and be ready
  provisioner "local-exec" {
    command = <<-EOT
      sleep 5
      until ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PubkeyAuthentication=no -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o ChallengeResponseAuthentication=no -o ConnectTimeout=2 ${self.ipv4_address}  2>&1 | grep "Permission denied"
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 2
      done
    EOT
  }
  
  # Generating and uploading the agent.conf file
  provisioner "file" {
    content = templatefile("${path.module}/templates/agent.conf.tpl", {
      server = "https://${local.first_control_plane_network_ip}:6443"
      token  = random_password.k3s_token.result
    })
    destination = "/etc/rancher/k3s/agent.conf"
  }

  # Generating k3s agent config file
  provisioner "file" {
    content = yamlencode({
      node-name     = self.name
      kubelet-arg   = "cloud-provider=external"
      flannel-iface = "eth1"
      node-ip       = cidrhost(hcloud_network_subnet.k3s.ip_range, 257 + count.index)
    })
    destination = "/etc/rancher/k3s/config.yaml"
  }

  # Run the agent
  provisioner "remote-exec" {
    inline = [
      # set the hostname in a persistent fashion
      "hostnamectl set-hostname ${self.name}",
      # first we disable automatic reboot (after transactional updates), and configure the reboot method as kured
      "rebootmgrctl set-strategy off && echo 'REBOOT_METHOD=kured' > /etc/transactional-update.conf",
      # then we start k3s agent and join the cluster
      "systemctl enable k3s-agent",
      <<-EOT
        until systemctl status k3s-agent > /dev/null
        do
          systemctl start k3s-agent
          echo "Starting k3s-agent and joining the cluster..."
          sleep 2
        done
      EOT
    ]
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = cidrhost(hcloud_network_subnet.k3s.ip_range, 257 + count.index)
  }

  depends_on = [
    hcloud_server.first_control_plane,
    hcloud_network_subnet.k3s
  ]
}
