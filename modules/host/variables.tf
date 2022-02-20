variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "name" {
  description = "Host name"
  type        = string
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

variable "ssh_keys" {
  description = "List of SSH key IDs"
  type        = list(string)
  nullable    = true
}

variable "firewall_ids" {
  description = "Set of firewal IDs"
  type        = set(number)
  nullable    = true
}

variable "placement_group_id" {
  description = "Placement group ID"
  type        = number
  nullable    = true
}

variable "labels" {
  description = "Labels"
  type        = map(any)
  nullable    = true
}

variable "location" {
  description = "The server location"
  type        = string
}

variable "network_id" {
  description = "The network or subnet id"
  type        = number
}

variable "ip" {
  description = "The IP"
  type        = string
  nullable    = true
}

variable "server_type" {
  description = "The server type"
  type        = string
}
