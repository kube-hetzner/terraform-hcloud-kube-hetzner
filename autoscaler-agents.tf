locals {
  cluster_prefix = var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""
  first_nodepool_snapshot_id = length(var.autoscaler_nodepools) == 0 ? "" : (
    local.snapshot_id_by_os[var.autoscaler_nodepools[0].os][substr(var.autoscaler_nodepools[0].server_type, 0, 3) == "cax" ? "arm" : "x86"]
  )

  imageList = {
    arm64 : length(var.autoscaler_nodepools) == 0 ? "" : tostring(local.snapshot_id_by_os[var.autoscaler_nodepools[0].os]["arm"])
    amd64 : length(var.autoscaler_nodepools) == 0 ? "" : tostring(local.snapshot_id_by_os[var.autoscaler_nodepools[0].os]["x86"])
  }

  nodeConfigName = var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""
  cluster_config = {
    imagesForArch : local.imageList
    nodeConfigs : {
      for index, nodePool in var.autoscaler_nodepools :
      ("${local.nodeConfigName}${nodePool.name}") => {
        cloudInit = data.cloudinit_config.autoscaler_config[index].rendered
        labels    = nodePool.labels
        taints    = nodePool.taints
      }
    }
  }

  isUsingLegacyConfig = length(var.autoscaler_labels) > 0 || length(var.autoscaler_taints) > 0

  autoscaler_yaml = length(var.autoscaler_nodepools) == 0 ? "" : templatefile(
    "${path.module}/templates/autoscaler.yaml.tpl",
    {
      cloudinit_config                           = local.isUsingLegacyConfig ? base64encode(data.cloudinit_config.autoscaler_legacy_config[0].rendered) : ""
      ca_image                                   = var.cluster_autoscaler_image
      ca_version                                 = var.cluster_autoscaler_version
      cluster_autoscaler_extra_args              = var.cluster_autoscaler_extra_args
      cluster_autoscaler_log_level               = var.cluster_autoscaler_log_level
      cluster_autoscaler_log_to_stderr           = var.cluster_autoscaler_log_to_stderr
      cluster_autoscaler_stderr_threshold        = var.cluster_autoscaler_stderr_threshold
      cluster_autoscaler_server_creation_timeout = tostring(var.cluster_autoscaler_server_creation_timeout)
      ssh_key                                    = local.hcloud_ssh_key_id
      ipv4_subnet_id                             = data.hcloud_network.k3s.id
      snapshot_id                                = local.first_nodepool_snapshot_id
      cluster_config                             = base64encode(jsonencode(local.cluster_config))
      firewall_id                                = hcloud_firewall.k3s.id
      cluster_name                               = local.cluster_prefix
      node_pools                                 = var.autoscaler_nodepools
  })
  # A concatenated list of all autoscaled nodes
  autoscaled_nodes = length(var.autoscaler_nodepools) == 0 ? {} : {
    for v in concat([
      for k, v in data.
      hcloud_servers.autoscaled_nodes : [for v in v.servers : v]
    ]...) : v.name => v
  }
}

resource "null_resource" "configure_autoscaler" {
  count = length(var.autoscaler_nodepools) > 0 ? 1 : 0

  triggers = {
    template = local.autoscaler_yaml
  }
  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port           = var.ssh_port
  }

  # Upload the autoscaler resource defintion
  provisioner "file" {
    content     = local.autoscaler_yaml
    destination = "/tmp/autoscaler.yaml"
  }

  # Create/Apply the definition
  provisioner "remote-exec" {
    inline = ["kubectl apply -f /tmp/autoscaler.yaml"]
  }

  depends_on = [
    hcloud_load_balancer.cluster,
    null_resource.control_planes,
    random_password.rancher_bootstrap,
    hcloud_volume.longhorn_volume,
    data.hcloud_image.microos_x86_snapshot,
    data.hcloud_image.microos_arm_snapshot,
    data.hcloud_image.leapmicro_x86_snapshot,
    data.hcloud_image.leapmicro_arm_snapshot
  ]
}

data "cloudinit_config" "autoscaler_config" {
  count = length(var.autoscaler_nodepools)

  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/templates/autoscaler-cloudinit.yaml.tpl",
      {
        hostname          = "autoscaler"
        sshAuthorizedKeys = concat([var.ssh_public_key], var.ssh_additional_public_keys)
        k3s_config = yamlencode({
          server        = "https://${var.use_control_plane_lb ? hcloud_load_balancer_network.control_plane.*.ip[0] : module.control_planes[keys(module.control_planes)[0]].private_ipv4_address}:6443"
          token         = local.k3s_token
          kubelet-arg   = concat(local.kubelet_arg, var.k3s_global_kubelet_args, var.k3s_autoscaler_kubelet_args, var.autoscaler_nodepools[count.index].kubelet_args)
          flannel-iface = local.flannel_iface
          node-label    = concat(local.default_agent_labels, [for k, v in var.autoscaler_nodepools[count.index].labels : "${k}=${v}"])
          node-taint    = concat(local.default_agent_taints, [for taint in var.autoscaler_nodepools[count.index].taints : "${taint.key}=${taint.value}:${taint.effect}"])
          selinux       = true
        })
        install_k3s_agent_script     = join("\n", concat(local.install_k3s_agent, ["systemctl start k3s-agent"]))
        cloudinit_write_files_common = local.cloudinit_write_files_common_by_os["microos"]
        cloudinit_runcmd_common      = local.cloudinit_runcmd_common_by_os["microos"]
      }
    )
  }
}

data "cloudinit_config" "autoscaler_legacy_config" {
  count = length(var.autoscaler_nodepools) > 0 && local.isUsingLegacyConfig ? 1 : 0

  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/templates/autoscaler-cloudinit.yaml.tpl",
      {
        hostname          = "autoscaler"
        sshAuthorizedKeys = concat([var.ssh_public_key], var.ssh_additional_public_keys)
        k3s_config = yamlencode({
          server        = "https://${var.use_control_plane_lb ? hcloud_load_balancer_network.control_plane.*.ip[0] : module.control_planes[keys(module.control_planes)[0]].private_ipv4_address}:6443"
          token         = local.k3s_token
          kubelet-arg   = local.kubelet_arg
          flannel-iface = local.flannel_iface
          node-label    = concat(local.default_agent_labels, var.autoscaler_labels)
          node-taint    = concat(local.default_agent_taints, var.autoscaler_taints)
          selinux       = true
        })
        install_k3s_agent_script     = join("\n", concat(local.install_k3s_agent, ["systemctl start k3s-agent"]))
        cloudinit_write_files_common = local.cloudinit_write_files_common_by_os["microos"]
        cloudinit_runcmd_common      = local.cloudinit_runcmd_common_by_os["microos"]
      }
    )
  }
}

data "hcloud_servers" "autoscaled_nodes" {
  for_each      = toset(var.autoscaler_nodepools[*].name)
  with_selector = "hcloud/node-group=${local.cluster_prefix}${each.value}"
}

resource "null_resource" "autoscaled_nodes_registries" {
  for_each = {
    for np in var.autoscaler_nodepools :
    np.name => np if length(data.hcloud_servers.autoscaled_nodes[np.name].servers) > 0
  }
  triggers = {
    registries = var.k3s_registries
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = data.hcloud_servers.autoscaled_nodes[each.key].servers[0].ipv4_address
    port           = var.ssh_port
  }

  provisioner "file" {
    content     = var.k3s_registries
    destination = "/tmp/registries.yaml"
  }

  provisioner "remote-exec" {
    inline = [local.k3s_registries_update_script]
  }
}
