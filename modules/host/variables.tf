variable "name" {
  description = "Host name"
  type        = string
}

variable "base_domain" {
  description = "Base domain used for reverse dns"
  type        = string
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
}

variable "ssh_public_key" {
  description = "SSH public Key"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private Key"
  type        = string
}

variable "ssh_additional_public_keys" {
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
  description = "Set of firewall IDs"
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

variable "ipv4_subnet_id" {
  description = "The subnet id"
  type        = string
}

variable "private_ipv4" {
  description = "Private IP for the server"
  type        = string
}

variable "server_type" {
  description = "The server type"
  type        = string
}

variable "backups" {
  description = "Enable backups"
  type        = bool
}

variable "packages_to_install" {
  description = "Packages to install"
  type        = list(string)
  default     = []
}

variable "dns_servers" {
  type        = list(string)
  description = "IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner"
}

variable "automatically_upgrade_os" {
  type    = bool
  default = true
}

variable "k3s_registries" {
  default = ""
  type    = string
}

variable "k3s_registries_update_script" {
  default = ""
  type    = string
}

variable "opensuse_microos_mirror_link" {
  default = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2"
  type    = string
}
