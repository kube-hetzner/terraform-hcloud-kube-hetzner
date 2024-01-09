# Rancher config
variable "rancher" {
  type = object({
    ## Enable Rancher
    enabled = optional(bool, false)

    ## The allowed values for the Rancher install channel are stable or latest
    install_channel = optional(string, "stable")

    ## Rancher hostname
    hostname = optional(string, "")

    ## Additional helm values file to pass to Rancher as 'valuesContent' at the HelmChart
    values = optional(string, "")
  })

  validation {
    condition     = contains(["stable", "latest"], var.rancher.install_channel)
    error_message = "The allowed values for the Rancher install channel are stable or latest."
  }

  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.rancher.hostname)) || var.rancher.hostname == ""
    error_message = "The hostname of the Rancher deployment must be a valid domain name (FQDN)."
  }

  default     = {}
  description = "Rancher config"
}

# Sensitive variables
variable "rancher_registration_manifest_url" {
  type        = string
  description = "The url of a rancher registration manifest to apply. (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/)"
  default     = ""
  sensitive   = true
}

variable "rancher_bootstrap_password" {
  type        = string
  default     = ""
  description = "Rancher bootstrap password"
  sensitive   = true

  validation {
    condition     = (length(var.rancher_bootstrap_password) >= 48) || (length(var.rancher_bootstrap_password) == 0)
    error_message = "The Rancher bootstrap password must be at least 48 characters long."
  }
}
