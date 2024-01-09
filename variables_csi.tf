# CSI config (Hetzner CSI, Longhorn, csi-driver-smb, Local Path Provisioner)
variable "csi" {
  type = object({
    ## Hetzner CSI config
    hetzner_csi = optional(object({
      ### Enable hetzner-csi
      enabled = optional(bool, true)

      ### The hetzner-csi version
      version = optional(string)
    }), {})

    ## Longhorn config
    longhorn = optional(object({
      ### Enable longhorn
      enabled = optional(bool, false)

      ### By default the official chart which may be incompatible with rancher is used
      ### WARNING: If you need to fully support rancher switch to https://charts.rancher.io
      repository = optional(string, "https://charts.longhorn.io")

      ### Namespace for longhorn deployment, defaults to \"longhorn-system\"
      namespace = optional(string, "longhorn-system")

      ### The longhorn fstype (ext4, xfs)
      fstype = optional(string, "ext4")

      ### Number of replicas for each longhorn volume
      volume_replica_count = optional(number, 3)

      ### Additional helm values file to pass to longhorn as 'valuesContent' at the HelmChart
      values = optional(string, "")
    }), {})

    ## csi-driver-smb config
    csi_driver_smb = optional(object({
      ### Enable csi-driver-smb
      enabled = optional(bool, false)

      ### Additional helm values file to pass to csi-driver-smb as 'valuesContent' at the HelmChart
      values = optional(string, "")
    }), {})

    ## Local Path Provisioner config
    local_storage = optional(object({
      ### Enable local-path-provisioner
      enabled = optional(bool, true)
    }), {})
  })

  ## Longhorn validation 
  validation {
    condition     = contains(["ext4", "xfs"], var.csi.longhorn.fstype)
    error_message = "Must be one of \"ext4\" or \"xfs\""
  }

  validation {
    condition     = var.csi.longhorn.volume_replica_count > 0
    error_message = "Number of longhorn volume replicas can't be below 1."
  }

  default     = {}
  description = "CSI config (Hetzner CSI, Longhorn, csi-driver-smb, Local Path Provisioner)"
}
