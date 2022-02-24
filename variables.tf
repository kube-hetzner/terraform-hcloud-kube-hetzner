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


variable "lb_server_type" {
  description = "Default load balancer server type"
  type        = string
}

variable "lb_disable_ipv6" {
  description = "Disable ipv6 for the load balancer"
  type        = bool
  default     = false
}

variable "servers_num" {
  description = "Number of control plane nodes."
  type        = number
}

variable "agents_num" {
  description = "Default agent server type"
  type        = number
}

variable "agent_nodepools" {
  description = "Number of agent nodes."
  type        = map(any)
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

variable "k3s_upgrade_channel" {
  type        = string
  default     = "stable"
  description = "Allows you to specify the k3s upgrade channel"
}

variable "automatically_upgrade_k3s" {
  type        = bool
  default     = true
  description = "Whether to automatically upgrade k3s based on the selected channel"
}
