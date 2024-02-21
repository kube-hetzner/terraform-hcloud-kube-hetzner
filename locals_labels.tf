locals {
  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
    "cluster"     = var.cluster_name
  }

  labels_control_plane_node = {
    role = "control_plane_node"
  }

  labels_control_plane_lb = {
    role = "control_plane_lb"
  }

  labels_agent_node = {
    role = "agent_node"
  }
}
