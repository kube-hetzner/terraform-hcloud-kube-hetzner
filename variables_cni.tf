# CNI plugin config (flannel, calico, cilium)
variable "cni" {
  type = object({
    ## CNI plugin type (flannel, calico, cilium)
    type = optional(string, "flannel")

    ## Use wireguard as the backend for CNI
    encrypt_traffic = optional(bool, false)

    ## Disable k3s default network policy controller (automatically true for calico and cilium)
    disable_network_policy = optional(bool, false)

    ## Calico config
    calico = optional(object({
      ### Version of Calico
      version = optional(string)

      ### Just a stub for a future helm implementation
      ### It can be used to replace the calico kustomize patch of the calico manifest
      values = optional(string, "")
    }), {})

    ## Cilium config
    cilium = optional(object({
      ### Version of Cilium
      version = optional(string, "1.14.4")

      ### Enables egress gateway to redirect and SNAT the traffic that leaves the cluster
      egress_gateway_enabled = optional(bool, false)

      ### Used when Cilium is configured in native routing mode
      ### The CNI assumes that the underlying network stack will forward packets to this destination without the need to apply SNAT. Default: value of \"cluster_ipv4_cidr\"
      ipv4_native_routing_cidr = optional(string)

      ### Set tunneling mode ("tunnel") or native-routing mode ("native")
      routing_mode = optional(string, "tunnel")

      ### Additional helm values file to pass to Cilium as 'valuesContent' at the HelmChart
      values = optional(string, "")
    }), {})
  })

  validation {
    condition     = contains(["flannel", "calico", "cilium"], var.cni.type)
    error_message = "The CNI type must be one of \"flannel\", \"calico\", or \"cilium\"."
  }

  validation {
    condition     = contains(["tunnel", "native"], var.cni.cilium.routing_mode)
    error_message = "The cilium_routing_mode must be one of \"tunnel\" or \"native\"."
  }

  default     = {}
  description = "CNI plugin config (flannel, calico, cilium)"
}
