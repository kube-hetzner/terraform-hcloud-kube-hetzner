variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "public_key" {
  description = "SSH public Key."
  type        = string
}

variable "private_key" {
  description = "SSH private Key."
  type        = string
}

variable "additional_public_keys" {
  description = "Additional SSH public Keys. Use them to grant other team members root access to your cluster nodes"
  type        = list(string)
  default     = []
}

variable "location" {
  description = "Default server location"
  type        = string
}

variable "network_region" {
  description = "Default region for network"
  type        = string
}

variable "control_plane_server_type" {
  description = "Default control plane server type"
  type        = string
}

variable "control_plane_count" {
  description = "Number of control plane nodes."
  type        = number
}

variable "load_balancer_type" {
  description = "Default load balancer server type"
  type        = string
}

variable "load_balancer_disable_ipv6" {
  description = "Disable ipv6 for the load balancer"
  type        = bool
  default     = false
}

variable "agent_nodepools" {
  description = "Number of agent nodes."
  type        = list(any)
  default     = []
}

variable "hetzner_ccm_version" {
  type        = string
  default     = null
  description = "Version of Kubernetes Cloud Controller Manager for Hetzner Cloud"
}

variable "hetzner_csi_version" {
  type        = string
  default     = null
  description = "Version of Container Storage Interface driver for Hetzner Cloud"
}

variable "traefik_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable or disbale k3s traefik installation"
}

variable "traefik_acme_tls" {
  type        = bool
  default     = false
  description = "Whether to include the TLS configuration with the Traefik configuration"
}

variable "traefik_acme_email" {
  type        = string
  default     = false
  description = "Email used to recieved expiration notice for certificate"
}

variable "allow_scheduling_on_control_plane" {
  type        = bool
  default     = false
  description = "Whether to allow non-control-plane workloads to run on the control-plane nodes"
}

variable "metrics_server_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable or disbale k3s mertric server"
}

variable "initial_k3s_channel" {
  type        = string
  default     = "stable"
  description = "Allows you to specify an initial k3s channel"

  validation {
    condition     = contains(["stable", "latest", "testing"], var.initial_k3s_channel)
    error_message = "The initial k3s channel must be one of stable, latest or testing."
  }
}

variable "automatically_upgrade_k3s" {
  type        = bool
  default     = true
  description = "Whether to automatically upgrade k3s based on the selected channel"
}

variable "extra_firewall_rules" {
  type        = list(any)
  default     = []
  description = "Additional firewall rules to apply to the cluster"
}

variable "use_cluster_name_in_node_name" {
  type        = bool
  default     = true
  description = "Whether to use the cluster name in the node name"
}

variable "cluster_name" {
  type        = string
  default     = "k3s"
  description = "Name of the cluster"

  validation {
    condition     = can(regex("^[a-z1-9\\-]+$", var.cluster_name))
    error_message = "The cluster name must be in the form of lowercase alphanumeric characters and/or dashes."
  }
}

variable "traefik_additional_options" {
  type    = list(string)
  default = []

}

variable "cni_plugin" {
  type        = string
  default     = "flannel"
  description = "CNI plugin for k3s"
}
