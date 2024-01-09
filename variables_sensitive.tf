# Tokens config
variable "hcloud_token" {
  type        = string
  sensitive   = true
  description = "Hetzner Cloud API Token"
}

variable "k3s_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "k3s master token (must match when restoring a cluster)"
}

# SSH config
variable "ssh_private_key" {
  description = "SSH private Key"
  type        = string
  sensitive   = true
}

# ETCD config
variable "etcd_s3_backup" {
  type        = map(any)
  sensitive   = true
  default     = {}
  description = "Etcd cluster state backup to S3 storage"
}
