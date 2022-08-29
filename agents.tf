module "agents" {
  source = "./modules/host"

  providers = {
    hcloud = hcloud,
  }

  for_each = local.agent_nodes

  name                       = "${var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""}${each.value.nodepool_name}"
  base_domain                = var.base_domain
  ssh_keys                   = [local.hcloud_ssh_key_id]
  ssh_port                   = var.ssh_port
  ssh_public_key             = var.ssh_public_key
  ssh_private_key            = var.ssh_private_key
  ssh_additional_public_keys = var.ssh_additional_public_keys
  firewall_ids               = [hcloud_firewall.k3s.id]
  placement_group_id         = var.placement_group_disable ? 0 : element(hcloud_placement_group.agent.*.id, ceil(each.value.index / 10))
  location                   = each.value.location
  server_type                = each.value.server_type
  ipv4_subnet_id             = hcloud_network_subnet.agent[[for i, v in var.agent_nodepools : i if v.name == each.value.nodepool_name][0]].id
  packages_to_install        = local.packages_to_install
  dns_servers                = var.dns_servers

  private_ipv4 = cidrhost(hcloud_network_subnet.agent[[for i, v in var.agent_nodepools : i if v.name == each.value.nodepool_name][0]].ip_range, each.value.index + 101)

  labels = merge(local.labels, local.labels_agent_node)

  depends_on = [
    hcloud_network_subnet.agent
  ]
}

resource "null_resource" "agents" {
  for_each = local.agent_nodes

  triggers = {
    agent_id = module.agents[each.key].id
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.agents[each.key].ipv4_address
    port           = var.ssh_port
  }

  # Generating k3s agent config file
  provisioner "file" {
    content = yamlencode({
      node-name     = module.agents[each.key].name
      server        = "https://${var.use_control_plane_lb ? hcloud_load_balancer_network.control_plane.*.ip[0] : module.control_planes[keys(module.control_planes)[0]].private_ipv4_address}:6443"
      token         = random_password.k3s_token.result
      kubelet-arg   = ["cloud-provider=external", "volume-plugin-dir=/var/lib/kubelet/volumeplugins"]
      flannel-iface = "eth1"
      node-ip       = module.agents[each.key].private_ipv4_address
      node-label    = each.value.labels
      node-taint    = each.value.taints
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
    hcloud_network_subnet.agent
  ]
}

resource "hcloud_volume" "volume" {
  for_each = { for key, val in local.agent_nodes : key => val if val.longhorn_volume_size >= 10 }

  labels = {
    provisioner = "terraform"
    scope       = "longhorn"
  }
  name      = "longhorn-${module.agents[each.key].name}"
  size      = local.agent_nodes[each.key].longhorn_volume_size
  server_id = module.agents[each.key].id
  automount = true
  format    = "ext4"
}

resource "null_resource" "configure_volumes" {
  for_each = { for key, val in local.agent_nodes : key => val if val.longhorn_volume_size >= 10 }

  triggers = {
    agent_id = module.agents[each.key].id
  }

  # Start the k3s agent and wait for it to have started
  provisioner "remote-exec" {
    inline = [
      "mkdir /var/longhorn >/dev/null 2>&1",
      "mount -o discard,defaults ${hcloud_volume.volume[each.key].linux_device} /var/longhorn",
      "resize2fs ${hcloud_volume.volume[each.key].linux_device}",
      "echo '${hcloud_volume.volume[each.key].linux_device} /var/longhorn ext4 discard,nofail,defaults 0 0' >> /etc/fstab"
    ]
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.agents[each.key].ipv4_address
  }

  depends_on = [
    hcloud_volume.volume
  ]
}