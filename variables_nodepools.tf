# Nodepools
variable "nodepools" {
  type = object({
    ## Control plane nodepools
    control_planes = list(object({
      name         = string
      server_type  = string
      location     = string
      backups      = optional(bool)
      labels       = list(string)
      taints       = list(string)
      count        = number
      swap_size    = optional(string, "")
      zram_size    = optional(string, "")
      kubelet_args = optional(list(string), ["kube-reserved=cpu=250m,memory=1500Mi,ephemeral-storage=1Gi", "system-reserved=cpu=250m,memory=300Mi"])
    }))

    ## Custom control plane configuration e.g to allow etcd monitoring
    #! TODO: Maybe this should be refactored into control_planes option
    control_planes_custom_config = optional(any, {})

    ## Agent nodepools
    agents = optional(list(object({
      name                 = string
      server_type          = string
      location             = string
      backups              = optional(bool)
      floating_ip          = optional(bool)
      labels               = list(string)
      taints               = list(string)
      count                = number
      longhorn_volume_size = optional(number)
      swap_size            = optional(string, "")
      zram_size            = optional(string, "")
      kubelet_args         = optional(list(string), ["kube-reserved=cpu=50m,memory=300Mi,ephemeral-storage=1Gi", "system-reserved=cpu=250m,memory=300Mi"])
    })), [])
  })

  ## Control planes validation
  validation {
    condition     = length(var.nodepools.control_planes) > 0
    error_message = "At least one control plane nodepool must be defined."
  }

  validation {
    condition     = var.nodepools.control_planes[0].count > 0
    error_message = "The first control plane nodepool must have at least one node."
  }

  validation {
    condition = length(
      [for control_plane_nodepool in var.nodepools.control_planes : control_plane_nodepool.name]
      ) == length(
      distinct(
        [for control_plane_nodepool in var.nodepools.control_planes : control_plane_nodepool.name]
      )
    )
    error_message = "Names in control_planes nodepools must be unique."
  }

  ## Agents validation
  validation {
    condition = length(
      [for agent_nodepool in var.nodepools.agents : agent_nodepool.name]
      ) == length(
      distinct(
        [for agent_nodepool in var.nodepools.agents : agent_nodepool.name]
      )
    )
    error_message = "Names in agents nodepools must be unique."
  }
}

#! TODO: This could be removed, does anyone use it? Is there a limit on name length?
variable "use_cluster_name_in_node_name" {
  type        = bool
  default     = true
  description = "Whether to use the cluster name in the node name."
}

#! TODO: This should be refactored into nodepools option (each nodepool can have a separate placement group)
variable "placement_group_disable" {
  type        = bool
  default     = false
  description = "Whether to disable placement groups."
}

#! TODO: This should be refactored into nodepools option
variable "allow_scheduling_on_control_plane" {
  type        = bool
  default     = false
  description = "Whether to allow non-control-plane workloads to run on the control-plane nodes."
}
