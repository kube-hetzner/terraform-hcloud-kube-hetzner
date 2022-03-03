module "agents" {
  source = "./modules/host"

  for_each = local.agent_nodepools

  name                   = each.key
  ssh_keys               = [hcloud_ssh_key.k3s.id]
  public_key             = var.public_key
  private_key            = var.private_key
  additional_public_keys = var.additional_public_keys
  firewall_ids           = [hcloud_firewall.k3s.id]
  placement_group_id     = hcloud_placement_group.k3s.id
  location               = var.location
  server_type            = each.value.server_type
  ipv4_subnet_id         = hcloud_network_subnet.subnet[each.value.subnet].id
  private_ipv4           = cidrhost(var.network_ipv4_subnets[each.value.subnet], each.value.index + 1)
  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }

  hcloud_token = var.hcloud_token

  depends_on = [
    hcloud_network_subnet.subnet
  ]
}

resource "null_resource" "agents" {
  for_each = local.agent_nodepools

  triggers = {
    agent_id = module.agents[each.key].id
  }

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = module.agents[each.key].ipv4_address
  }

  # Generating k3s agent config file
  provisioner "file" {
    content = yamlencode({
      node-name     = module.agents[each.key].name
      server        = "https://${local.first_control_plane_network_ipv4}:6443"
      token         = random_password.k3s_token.result
      kubelet-arg   = "cloud-provider=external"
      flannel-iface = "eth1"
      node-ip       = module.agents[each.key].ipv4_address
      node-label    = var.automatically_upgrade_k3s ? ["k3s_upgrade=true"] : []
    })
    destination = "/tmp/config.yaml"
  }

  # Install k3s agent
  provisioner "remote-exec" {
    inline = local.install_k3s_agent
  }

  # Start the k3s agent and wait for it to have started
  provisioner "remote-exec" {
    inline = [
      "systemctl start k3s-agent 2> /dev/null",
      <<-EOT
      timeout 120 bash <<EOF
        until systemctl status k3s-agent > /dev/null; do
          systemctl start k3s-agent 2> /dev/null
          echo "Waiting for the k3s agent to start..."
          sleep 2
        done
      EOF
      EOT
    ]
  }

  depends_on = [
    null_resource.first_control_plane,
    hcloud_network_subnet.subnet
  ]
}
