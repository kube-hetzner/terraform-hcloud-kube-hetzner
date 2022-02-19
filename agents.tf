module "agents" {
  source = "./modules/host"

  count = var.agents_num
  name  = "k3s-agent-${count.index}"

  ssh_keys           = [hcloud_ssh_key.k3s.id]
  public_key         = var.public_key
  private_key        = var.private_key
  firewall_ids       = [hcloud_firewall.k3s.id]
  placement_group_id = hcloud_placement_group.k3s.id
  location           = var.location
  network_id         = hcloud_network.k3s.id
  ip                 = cidrhost(hcloud_network_subnet.k3s.ip_range, 513 + count.index)
  server_type        = var.control_plane_server_type

  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }

  hcloud_token = var.hcloud_token
}

resource "null_resource" "agents" {
  count = var.agents_num

  triggers = {
    agent_id = module.agents[count.index].id
  }

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = module.agents[count.index].ipv4_address
  }

  # Generating k3s agent config file
  provisioner "file" {
    content = yamlencode({
      node-name     = module.agents[count.index].name
      server        = "https://${local.first_control_plane_network_ip}:6443"
      token         = random_password.k3s_token.result
      kubelet-arg   = "cloud-provider=external"
      flannel-iface = "eth1"
      node-ip       = cidrhost(hcloud_network_subnet.k3s.ip_range, 513 + count.index)
      node-label    = var.automatically_upgrade_k3s ? ["k3s_upgrade=true"] : []
    })
    destination = "/tmp/config.yaml"
  }

  # Install k3s agent
  provisioner "remote-exec" {
    inline = local.install_k3s_agent
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

  depends_on = [
    null_resource.first_control_plane,
    hcloud_network_subnet.k3s
  ]
}
