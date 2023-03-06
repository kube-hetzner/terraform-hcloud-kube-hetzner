module "agents" {
  source = "./modules/host"

  providers = {
    hcloud = hcloud,
  }

  for_each = local.agent_nodes

  name                         = "${var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""}${each.value.nodepool_name}"
  base_domain                  = var.base_domain
  ssh_keys                     = length(var.ssh_hcloud_key_label) > 0 ? concat([local.hcloud_ssh_key_id], data.hcloud_ssh_keys.keys_by_selector[0].ssh_keys.*.id) : [local.hcloud_ssh_key_id]
  ssh_port                     = var.ssh_port
  ssh_public_key               = var.ssh_public_key
  ssh_private_key              = var.ssh_private_key
  ssh_additional_public_keys   = length(var.ssh_hcloud_key_label) > 0 ? concat(var.ssh_additional_public_keys, data.hcloud_ssh_keys.keys_by_selector[0].ssh_keys.*.public_key) : var.ssh_additional_public_keys
  firewall_ids                 = [hcloud_firewall.k3s.id]
  placement_group_id           = var.placement_group_disable ? 0 : hcloud_placement_group.agent[floor(each.value.index / 10)].id
  location                     = each.value.location
  server_type                  = each.value.server_type
  backups                      = each.value.backups
  ipv4_subnet_id               = hcloud_network_subnet.agent[[for i, v in var.agent_nodepools : i if v.name == each.value.nodepool_name][0]].id
  packages_to_install          = local.packages_to_install
  dns_servers                  = var.dns_servers
  k3s_registries               = var.k3s_registries
  k3s_registries_update_script = local.k3s_registries_update_script
  opensuse_microos_mirror_link = var.opensuse_microos_mirror_link

  private_ipv4 = cidrhost(hcloud_network_subnet.agent[[for i, v in var.agent_nodepools : i if v.name == each.value.nodepool_name][0]].ip_range, each.value.index + 101)

  labels = merge(local.labels, local.labels_agent_node)

  automatically_upgrade_os = var.automatically_upgrade_os

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
      kubelet-arg   = local.kubelet_arg
      flannel-iface = local.flannel_iface
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

resource "hcloud_volume" "longhorn_volume" {
  for_each = { for k, v in local.agent_nodes : k => v if((lookup(v, "longhorn_volume_size", 0) >= 10) && (lookup(v, "longhorn_volume_size", 0) <= 10000) && var.enable_longhorn) }

  labels = {
    provisioner = "terraform"
    cluster     = var.cluster_name
    scope       = "longhorn"
  }
  name      = "${var.cluster_name}-longhorn-${module.agents[each.key].name}"
  size      = lookup(local.agent_nodes[each.key], "longhorn_volume_size", 0)
  server_id = module.agents[each.key].id
  automount = true
  format    = var.longhorn_fstype
}

resource "null_resource" "configure_longhorn_volume" {
  for_each = { for k, v in local.agent_nodes : k => v if((lookup(v, "longhorn_volume_size", 0) >= 10) && (lookup(v, "longhorn_volume_size", 0) <= 10000) && var.enable_longhorn) }

  triggers = {
    agent_id = module.agents[each.key].id
  }

  # Start the k3s agent and wait for it to have started
  provisioner "remote-exec" {
    inline = [
      "mkdir /var/longhorn >/dev/null 2>&1",
      "mount -o discard,defaults ${hcloud_volume.longhorn_volume[each.key].linux_device} /var/longhorn",
      "${var.longhorn_fstype == "ext4" ? "resize2fs" : "xfs_growfs"} ${hcloud_volume.longhorn_volume[each.key].linux_device}",
      "echo '${hcloud_volume.longhorn_volume[each.key].linux_device} /var/longhorn ${var.longhorn_fstype} discard,nofail,defaults 0 0' >> /etc/fstab"
    ]
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.agents[each.key].ipv4_address
    port           = var.ssh_port
  }

  depends_on = [
    hcloud_volume.longhorn_volume
  ]
}

resource "hcloud_floating_ip" "agents" {
  for_each = { for k, v in local.agent_nodes : k => v if coalesce(lookup(v, "floating_ip"), false) }

  type          = "ipv4"
  labels        = local.labels
  home_location = each.value.location
}

resource "hcloud_floating_ip_assignment" "agents" {
  for_each = { for k, v in local.agent_nodes : k => v if coalesce(lookup(v, "floating_ip"), false) }

  floating_ip_id = hcloud_floating_ip.agents[each.key].id
  server_id      = module.agents[each.key].id

  depends_on = [
    null_resource.agents
  ]
}

resource "null_resource" "configure_floating_ip" {
  for_each = { for k, v in local.agent_nodes : k => v if coalesce(lookup(v, "floating_ip"), false) }

  triggers = {
    agent_id       = module.agents[each.key].id
    floating_ip_id = hcloud_floating_ip.agents[each.key].id
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"BOOTPROTO='static'\nSTARTMODE='auto'\nIPADDR=${hcloud_floating_ip.agents[each.key].ip_address}/32\nIPADDR_1=${module.agents[each.key].ipv4_address}/32\" > /etc/sysconfig/network/ifcfg-eth0",
      "echo \"172.31.1.1 - 255.255.255.255 eth0\ndefault 172.31.1.1 - eth0 src ${hcloud_floating_ip.agents[each.key].ip_address}\" > /etc/sysconfig/network/ifroute-eth0",

      "ip addr add ${hcloud_floating_ip.agents[each.key].ip_address}/32 dev eth0",
      "ip route replace default via 172.31.1.1 dev eth0 src ${hcloud_floating_ip.agents[each.key].ip_address}",

      # its important: floating IP should be first on the interface IP list
      # move main IP to the second position
      "ip addr del ${module.agents[each.key].ipv4_address}/32 dev eth0",
      "ip addr add ${module.agents[each.key].ipv4_address}/32 dev eth0",
    ]
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.agents[each.key].ipv4_address
    port           = var.ssh_port
  }

  depends_on = [
    hcloud_floating_ip_assignment.agents
  ]
}
