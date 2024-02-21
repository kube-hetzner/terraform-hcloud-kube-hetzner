locals {
  control_plane_nodes = merge([
    for pool_index, nodepool_obj in var.nodepools.control_planes : {
      for node_index in range(nodepool_obj.count) :
      format("%s-%s-%s", pool_index, node_index, nodepool_obj.name) => {
        nodepool_name : nodepool_obj.name,
        server_type : nodepool_obj.server_type,
        location : nodepool_obj.location,
        labels : concat(local.default_control_plane_labels, nodepool_obj.swap_size != "" ? local.swap_node_label : [], nodepool_obj.labels),
        taints : concat(local.default_control_plane_taints, nodepool_obj.taints),
        kubelet_args : nodepool_obj.kubelet_args,
        backups : nodepool_obj.backups,
        swap_size : nodepool_obj.swap_size,
        zram_size : nodepool_obj.zram_size,
        index : node_index
      }
    }
  ]...)

  agent_nodes = merge([
    for pool_index, nodepool_obj in var.nodepools.agents : {
      for node_index in range(nodepool_obj.count) :
      format("%s-%s-%s", pool_index, node_index, nodepool_obj.name) => {
        nodepool_name : nodepool_obj.name,
        server_type : nodepool_obj.server_type,
        longhorn_volume_size : coalesce(nodepool_obj.longhorn_volume_size, 0),
        floating_ip : lookup(nodepool_obj, "floating_ip", false),
        location : nodepool_obj.location,
        labels : concat(local.default_agent_labels, nodepool_obj.swap_size != "" ? local.swap_node_label : [], nodepool_obj.labels),
        taints : concat(local.default_agent_taints, nodepool_obj.taints),
        kubelet_args : nodepool_obj.kubelet_args,
        backups : lookup(nodepool_obj, "backups", false),
        swap_size : nodepool_obj.swap_size,
        zram_size : nodepool_obj.zram_size,
        index : node_index
      }
    }
  ]...)

  # if we are in a single cluster config, we use the default klipper lb instead of Hetzner LB
  control_plane_count    = sum([for v in var.nodepools.control_planes : v.count])
  agent_count            = sum([for v in var.nodepools.agents : v.count])
  is_single_node_cluster = (local.control_plane_count + local.agent_count) == 1

  # Determine if scheduling should be allowed on control plane nodes, which will be always true for single node clusters and clusters or if scheduling is allowed on control plane nodes
  allow_scheduling_on_control_plane = local.is_single_node_cluster ? true : var.allow_scheduling_on_control_plane

  # Determine if loadbalancer target should be allowed on control plane nodes, which will be always true for single node clusters or if scheduling is allowed on control plane nodes
  allow_loadbalancer_target_on_control_plane = local.is_single_node_cluster ? true : var.allow_scheduling_on_control_plane

  # Default k3s node labels
  default_agent_labels         = concat([], var.automatic_updates.k3s ? ["k3s_upgrade=true"] : [])
  default_control_plane_labels = concat(local.allow_loadbalancer_target_on_control_plane ? [] : ["node.kubernetes.io/exclude-from-external-load-balancers=true"], var.automatic_updates.k3s ? ["k3s_upgrade=true"] : [])

  # Default k3s node taints
  default_control_plane_taints = concat([], local.allow_scheduling_on_control_plane ? [] : ["node-role.kubernetes.io/control-plane:NoSchedule"])
  default_agent_taints         = concat([], var.cni.type == "cilium" ? ["node.cilium.io/agent-not-ready:NoExecute"] : [])

  swap_node_label = ["node.kubernetes.io/server-swap=enabled"]
}
