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

variable "location" {
  description = "Default server location"
  type        = string
}

variable "control_plane_server_type" {
  description = "Default control plane server type"
  type        = string
}

variable "agent_server_type" {
  description = "Default agent server type"
  type        = string
}

variable "lb_server_type" {
  description = "Default load balancer server type"
  type        = string
}

variable "servers_num" {
  description = "Number of control plane nodes."
  type        = number
}

variable "agents_num" {
  description = "Number of agent nodes."
  type        = number
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
