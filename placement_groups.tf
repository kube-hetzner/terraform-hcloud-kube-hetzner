locals {
  control_plane_placement_compat_groups = max(
    0,
    [
      for cp_pool in var.control_plane_nodepools :
      cp_pool.placement_group_compat_idx + 1 if cp_pool.placement_group_compat_idx != null && cp_pool.placement_group == null
    ]...
  )
  control_plane_groups = toset(
    [
      for cp_pool in var.control_plane_nodepools :
      cp_pool.placement_group if cp_pool.placement_group != null
    ]
  )
  agent_placement_compat_groups = max(
    0,
    [
      for ag_pool in var.agent_nodepools :
      ag_pool.placement_group_compat_idx + 1 if ag_pool.placement_group_compat_idx != null && ag_pool.placement_group == null
    ]...
  )
  agent_placement_groups = toset(
    concat(
      [
        for ag_pool in var.agent_nodepools :
        ag_pool.placement_group if ag_pool.placement_group != null
      ],
      concat(
        [
          for ag_pool in var.agent_nodepools :
          [
            for node, node_config in coalesce(ag_pool.nodes, {}) :
            node_config.placement_group if node_config.placement_group != null
          ]
        ]
      )...
    )
  )
}

resource "hcloud_placement_group" "control_plane" {
  count  = local.control_plane_placement_compat_groups
  name   = "${var.cluster_name}-control-plane-${count.index + 1}"
  labels = local.labels
  type   = "spread"
}

resource "hcloud_placement_group" "control_plane_named" {
  for_each = local.control_plane_groups
  name     = "${var.cluster_name}-control-plane-${each.key}"
  labels   = local.labels
  type     = "spread"
}

resource "hcloud_placement_group" "agent" {
  count  = local.agent_placement_compat_groups
  name   = "${var.cluster_name}-agent-${count.index + 1}"
  labels = local.labels
  type   = "spread"
}

resource "hcloud_placement_group" "agent_named" {
  for_each = local.agent_placement_groups
  name     = "${var.cluster_name}-agent-${each.key}"
  labels   = local.labels
  type     = "spread"
}
