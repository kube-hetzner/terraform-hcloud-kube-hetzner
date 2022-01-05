variable "hcloud_token" {
  description = "Hetzner API tokey"
  type        = string
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "public_key" {
  description = "SSH public Key."
  type        = string
}

variable "private_key" {
  description = "SSH private Key."
  type        = string
}

variable "servers_num" {
  description = "Number of control plane nodes."
  default     = 2
}

variable "agents_num" {
  description = "Number of agent nodes."
  default     = 2
}

variable "location" {
  description = "Default server location"
  default     = "fsn1"
}


variable "control_plane_server_type" {
  description = "Default control plane server type"
  default     = "cx11"

}

variable "agent_server_type" {
  description = "Default agent server type"
  default     = "cx21"
}

variable "lb_server_type" {
  description = "Default load balancer server type"
  default     = "lb11"
}
