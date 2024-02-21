locals {
  control_plane_groups = toset(
    [
      for node in local.control_plane_nodes :
      node.placement_group_name if node.placement_group_name != null
    ]
  )
  agent_placement_groups = toset(
    [
      for node in local.agent_nodes :
      node.placement_group_name if node.placement_group_name != null
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
