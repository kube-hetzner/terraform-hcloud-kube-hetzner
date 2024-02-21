# Automatic updates config (k3s, OS & Kured)
variable "automatic_updates" {
  type = object({
    ## Automatically updates k3s to latest patch version of the selected channel
    k3s = optional(bool, true)

    ## Automatically updates host OS for all nodes
    ##! WARNING: Should be disabled for single-node clusters
    os = optional(bool, true)

    ## Kured update controller config
    kured = optional(object({
      ### Version of Kured
      version = optional(string)

      ### Additional options for Kured (merged with default options)
      options = optional(map(string), {})
    }), {})
  })

  default     = {}
  description = "Automatic updates config (k3s, OS & Kured)"
}
