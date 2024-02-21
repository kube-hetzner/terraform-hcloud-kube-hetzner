locals {
  control_plane_groups = toset(
    [
      for cp_pool in var.control_plane_nodepools :
      cp_pool.placement_group if cp_pool.placement_group != null
    ]
  )
  agent_placement_groups = toset(
    [
      for ag_pool in var.agent_nodepools :
      ag_pool.placement_group if ag_pool.placement_group != null
    ]
  )
}

resource "hcloud_placement_group" "control_plane" {
  for_each = local.control_plane_groups
  name     = "${var.cluster_name}-control-plane-${each.key}"
  labels   = local.labels
  type     = "spread"
}

resource "hcloud_placement_group" "agent" {
  for_each = local.agent_placement_groups
  name     = "${var.cluster_name}-agent-${each.key}"
  labels   = local.labels
  type     = "spread"
}
