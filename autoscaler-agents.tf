locals {
  cluster_prefix = var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""
  first_nodepool_snapshot_id = length(var.autoscaler_nodes.nodepools) == 0 ? "" : (
    substr(var.autoscaler_nodes.nodepools[0].server_type, 0, 3) == "cax" ? data.hcloud_image.microos_arm_snapshot.id : data.hcloud_image.microos_x86_snapshot.id
  )

  imageList = {
    arm64 : tostring(data.hcloud_image.microos_arm_snapshot.id)
    amd64 : tostring(data.hcloud_image.microos_x86_snapshot.id)
  }

  nodeConfigName = var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""
  cluster_config = {
    imagesForArch : local.imageList
    nodeConfigs : {
      for index, nodePool in var.autoscaler_nodes.nodepools :
      ("${local.nodeConfigName}${nodePool.name}") => {
        cloudInit = data.cloudinit_config.autoscaler_config[index].rendered
        labels    = nodePool.labels
        taints    = nodePool.taints
      }
    }
  }

  isUsingLegacyConfig = length(var.autoscaler_nodes.labels) > 0 || length(var.autoscaler_nodes.taints) > 0

  autoscaler_yaml = length(var.autoscaler_nodes.nodepools) == 0 ? "" : templatefile(
    "${path.module}/templates/autoscaler.yaml.tpl",
    {
      cloudinit_config                    = local.isUsingLegacyConfig ? base64encode(data.cloudinit_config.autoscaler_legacy_config[0].rendered) : ""
      ca_image                            = var.cluster_autoscaler.image
      ca_version                          = var.cluster_autoscaler.version
      cluster_autoscaler_extra_args       = var.cluster_autoscaler.extra_args
      cluster_autoscaler_log_level        = var.cluster_autoscaler.log_level
      cluster_autoscaler_log_to_stderr    = var.cluster_autoscaler.log_to_stderr
      cluster_autoscaler_stderr_threshold = var.cluster_autoscaler.stderr_threshold
      ssh_key                             = local.ssh.hcloud_ssh_key_id
      ipv4_subnet_id                      = data.hcloud_network.k3s.id
      snapshot_id                         = local.first_nodepool_snapshot_id
      cluster_config                      = base64encode(jsonencode(local.cluster_config))
      firewall_id                         = hcloud_firewall.k3s.id
      cluster_name                        = local.cluster_prefix
      node_pools                          = var.autoscaler_nodes.nodepools
  })
  # A concatenated list of all autoscaled nodes
  autoscaled_nodes = length(var.autoscaler_nodes.nodepools) == 0 ? {} : {
    for v in concat([
      for k, v in data.
      hcloud_servers.autoscaled_nodes : [for v in v.servers : v]
    ]...) : v.name => v
  }
}

resource "null_resource" "configure_autoscaler" {
  count = length(var.autoscaler_nodes.nodepools) > 0 ? 1 : 0

  triggers = {
    template = local.autoscaler_yaml
  }
  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh.agent_identity
    host           = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port           = var.ssh.port
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
    null_resource.kustomization,
    data.hcloud_image.microos_x86_snapshot
  ]
}

data "cloudinit_config" "autoscaler_config" {
  count = length(var.autoscaler_nodes.nodepools)

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
        sshAuthorizedKeys = concat([var.ssh.public_key], var.ssh.additional_public_keys)
        k3s_config = yamlencode({
          server        = "https://${var.load_balancer.kubeapi.enabled ? hcloud_load_balancer_network.control_plane.*.ip[0] : module.control_planes[keys(module.control_planes)[0]].private_ipv4_address}:6443"
          token         = local.k3s.token
          kubelet-arg   = local.kubelet_arg
          flannel-iface = local.cni.flannel.iface
          node-label    = concat(local.default_agent_labels, [for k, v in var.autoscaler_nodes.nodepools[count.index].labels : "${k}=${v}"])
          node-taint    = concat(local.default_agent_taints, [for taint in var.autoscaler_nodes.nodepools[count.index].taints : "${taint.key}=${taint.value}:${taint.effect}"])
          selinux       = true
        })
        install_k3s_agent_script     = join("\n", concat(local.k3s.install.agent, ["systemctl start k3s-agent"]))
        cloudinit_write_files_common = local.cloudinit.write_files_common
        cloudinit_runcmd_common      = local.cloudinit.runcmd_common
      }
    )
  }
}

data "cloudinit_config" "autoscaler_legacy_config" {
  count = length(var.autoscaler_nodes.nodepools) > 0 && local.isUsingLegacyConfig ? 1 : 0

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
        sshAuthorizedKeys = concat([var.ssh.public_key], var.ssh.additional_public_keys)
        k3s_config = yamlencode({
          server        = "https://${var.load_balancer.kubeapi.enabled ? hcloud_load_balancer_network.control_plane.*.ip[0] : module.control_planes[keys(module.control_planes)[0]].private_ipv4_address}:6443"
          token         = local.k3s.token
          kubelet-arg   = local.kubelet_arg
          flannel-iface = local.cni.flannel.iface
          node-label    = concat(local.default_agent_labels, var.autoscaler_nodes.labels)
          node-taint    = concat(local.default_agent_taints, var.autoscaler_nodes.taints)
          selinux       = true
        })
        install_k3s_agent_script     = join("\n", concat(local.k3s.install.agent, ["systemctl start k3s-agent"]))
        cloudinit_write_files_common = local.cloudinit.write_files_common
        cloudinit_runcmd_common      = local.cloudinit.runcmd_common
      }
    )
  }
}

data "hcloud_servers" "autoscaled_nodes" {
  for_each      = toset(var.autoscaler_nodes.nodepools[*].name)
  with_selector = "hcloud/node-group=${local.cluster_prefix}${each.value}"
}

resource "null_resource" "autoscaled_nodes_registries" {
  for_each = local.autoscaled_nodes
  triggers = {
    registries = var.k3s.registries
  }

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh.agent_identity
    host           = each.value.ipv4_address
    port           = var.ssh.port
  }

  provisioner "file" {
    content     = var.k3s.registries
    destination = "/tmp/registries.yaml"
  }

  provisioner "remote-exec" {
    inline = [local.k3s.registries_update_script]
  }
}
