module "control_planes" {
  source = "./modules/host"

  providers = {
    hcloud = hcloud,
  }

  for_each = local.control_plane_nodes

  name                         = "${var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""}${each.value.nodepool_name}"
  microos_snapshot_id          = substr(each.value.server_type, 0, 3) == "cax" ? data.hcloud_image.microos_arm_snapshot.id : data.hcloud_image.microos_x86_snapshot.id
  base_domain                  = var.base_domain
  ssh_keys                     = length(var.ssh_hcloud_key_label) > 0 ? concat([local.hcloud_ssh_key_id], data.hcloud_ssh_keys.keys_by_selector[0].ssh_keys.*.id) : [local.hcloud_ssh_key_id]
  ssh_port                     = var.ssh_port
  ssh_public_key               = var.ssh_public_key
  ssh_private_key              = var.ssh_private_key
  ssh_additional_public_keys   = length(var.ssh_hcloud_key_label) > 0 ? concat(var.ssh_additional_public_keys, data.hcloud_ssh_keys.keys_by_selector[0].ssh_keys.*.public_key) : var.ssh_additional_public_keys
  firewall_ids                 = [hcloud_firewall.k3s.id]
  placement_group_id           = var.placement_group_disable ? null : hcloud_placement_group.control_plane[floor(index(keys(local.control_plane_nodes), each.key) / 10)].id
  location                     = each.value.location
  server_type                  = each.value.server_type
  backups                      = each.value.backups
  ipv4_subnet_id               = hcloud_network_subnet.control_plane[[for i, v in var.control_plane_nodepools : i if v.name == each.value.nodepool_name][0]].id
  dns_servers                  = var.dns_servers
  k3s_registries               = var.k3s_registries
  k3s_registries_update_script = local.k3s_registries_update_script
  cloudinit_write_files_common = local.cloudinit_write_files_common
  cloudinit_runcmd_common      = local.cloudinit_runcmd_common

  # We leave some room so 100 eventual Hetzner LBs that can be created perfectly safely
  # It leaves the subnet with 254 x 254 - 100 = 64416 IPs to use, so probably enough.
  private_ipv4 = cidrhost(hcloud_network_subnet.control_plane[[for i, v in var.control_plane_nodepools : i if v.name == each.value.nodepool_name][0]].ip_range, each.value.index + 101)

  labels = merge(local.labels, local.labels_control_plane_node)

  automatically_upgrade_os = var.automatically_upgrade_os

  depends_on = [
    hcloud_network_subnet.control_plane,
    hcloud_placement_group.control_plane,
  ]
}

resource "hcloud_load_balancer" "control_plane" {
  count = var.use_control_plane_lb ? 1 : 0
  name  = "${var.cluster_name}-control-plane"

  load_balancer_type = var.control_plane_lb_type
  location           = var.load_balancer_location
  labels             = merge(local.labels, local.labels_control_plane_lb)
}

resource "hcloud_load_balancer_network" "control_plane" {
  count = var.use_control_plane_lb ? 1 : 0

  load_balancer_id = hcloud_load_balancer.control_plane.*.id[0]
  subnet_id        = hcloud_network_subnet.control_plane.*.id[0]
}

resource "hcloud_load_balancer_target" "control_plane" {
  count = var.use_control_plane_lb ? 1 : 0

  depends_on       = [hcloud_load_balancer_network.control_plane]
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.control_plane.*.id[0]
  label_selector   = join(",", [for k, v in merge(local.labels, local.labels_control_plane_node) : "${k}=${v}"])
  use_private_ip   = true
}

resource "hcloud_load_balancer_service" "control_plane" {
  count = var.use_control_plane_lb ? 1 : 0

  load_balancer_id = hcloud_load_balancer.control_plane.*.id[0]
  protocol         = "tcp"
  destination_port = "6443"
  listen_port      = "6443"
}

resource "null_resource" "control_planes" {
  for_each = local.control_plane_nodes

  triggers = {
    control_plane_id = module.control_planes[each.key].id
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[each.key].ipv4_address
    port           = var.ssh_port
  }

  # Generating k3s server config file
  provisioner "file" {
    content = yamlencode(
      merge(
        {
          node-name = module.control_planes[each.key].name
          server = length(module.control_planes) == 1 ? null : "https://${
            var.use_control_plane_lb ? hcloud_load_balancer_network.control_plane.*.ip[0] :
            module.control_planes[each.key].private_ipv4_address == module.control_planes[keys(module.control_planes)[0]].private_ipv4_address ?
            module.control_planes[keys(module.control_planes)[1]].private_ipv4_address :
          module.control_planes[keys(module.control_planes)[0]].private_ipv4_address}:6443"
          token                       = random_password.k3s_token.result
          disable-cloud-controller    = true
          disable                     = local.disable_extras
          kubelet-arg                 = local.kubelet_arg
          kube-controller-manager-arg = local.kube_controller_manager_arg
          flannel-iface               = local.flannel_iface
          node-ip                     = module.control_planes[each.key].private_ipv4_address
          advertise-address           = module.control_planes[each.key].private_ipv4_address
          node-label                  = each.value.labels
          node-taint                  = each.value.taints
          selinux                     = true
          write-kubeconfig-mode       = "0644" # needed for import into rancher
        },
        lookup(local.cni_k3s_settings, var.cni_plugin, {}),
        var.use_control_plane_lb ? {
          tls-san = concat([hcloud_load_balancer.control_plane.*.ipv4[0], hcloud_load_balancer_network.control_plane.*.ip[0]], var.additional_tls_sans)
          } : {
          tls-san = concat([
            module.control_planes[each.key].ipv4_address
          ], var.additional_tls_sans)
        },
        local.etcd_s3_snapshots,
        var.control_planes_custom_config
      )
    )

    destination = "/tmp/config.yaml"
  }

  # Install k3s server
  provisioner "remote-exec" {
    inline = local.install_k3s_server
  }

  # Start the k3s server and wait for it to have started correctly
  provisioner "remote-exec" {
    inline = [
      "systemctl start k3s 2> /dev/null",
      <<-EOT
      timeout 120 bash <<EOF
        until systemctl status k3s > /dev/null; do
          systemctl start k3s 2> /dev/null
          echo "Waiting for the k3s server to start..."
          sleep 3
        done
      EOF
      EOT
    ]
  }

  depends_on = [
    null_resource.first_control_plane,
    hcloud_network_subnet.control_plane
  ]
}
