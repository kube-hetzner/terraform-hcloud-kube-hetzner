locals {
  labels = {
    general = {
      "provisioner" = "terraform",
      "engine"      = "k3s"
      "cluster"     = var.cluster_name
    }

    control_plane_node = {
      role = "control_plane_node"
    }

    control_plane_lb = {
      role = "control_plane_lb"
    }

    agent_node = {
      role = "agent_node"
    }
  }
}
