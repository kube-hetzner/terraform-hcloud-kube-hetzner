module "agents" {
  source = "./modules/host"

  for_each = local.agent_nodepools

  name                   = "${var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""}${each.value.nodepool_name}"
  ssh_keys               = [hcloud_ssh_key.k3s.id]
  public_key             = var.public_key
  private_key            = var.private_key
  additional_public_keys = var.additional_public_keys
  firewall_ids           = [hcloud_firewall.k3s.id]
  placement_group_id     = hcloud_placement_group.k3s.id
  location               = var.location
  server_type            = each.value.server_type
  ipv4_subnet_id         = hcloud_network_subnet.subnet[[for i, v in var.agent_nodepools : i if v.name == each.value.nodepool_name][0] + 2].id

  # We leave some room so 100 eventual Hetzner LBs that can be created perfectly safely
  # It leaves the subnet with 254 x 254 - 100 = 64416 IPs to use, so probably enough.
  private_ipv4 = cidrhost(local.network_ipv4_subnets[[for i, v in var.agent_nodepools : i if v.name == each.value.nodepool_name][0] + 2], each.value.index + 101)

  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }

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
    content = yamlencode(merge({
      node-name     = module.agents[each.key].name
      server        = "https://${module.control_planes[0].private_ipv4_address}:6443"
      token         = random_password.k3s_token.result
      kubelet-arg   = "cloud-provider=external"
      flannel-iface = "eth1"
      node-ip       = module.agents[each.key].private_ipv4_address
      node-label    = var.automatically_upgrade_k3s ? ["k3s_upgrade=true"] : []
    },
      var.cni_plugin == "calico" ? {
        flannel-backend             = "none"
        kube-controller-manager-arg = "flex-volume-plugin-dir=/var/lib/kubelet/volumeplugins"
      } : {}))
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
