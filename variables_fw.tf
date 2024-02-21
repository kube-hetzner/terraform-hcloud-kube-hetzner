# Firewall config
variable "firewall" {
  type = object({
    ## Whether or not to restrict the outbound traffic
    restrict_outbound_traffic = optional(bool, true)

    ## Block entering ICMP ping
    block_icmp_ping_in = optional(bool, false)

    ## Source networks that have Kube API access to the servers
    kube_api_source = optional(list(string), ["0.0.0.0/0", "::/0"])

    ## Source networks that have SSH access to the servers
    ssh_source = optional(list(string), ["0.0.0.0/0", "::/0"])

    ## Additional firewall rules to apply to the cluster
    extra_rules = optional(list(any), [])
  })

  default     = {}
  description = "Firewall config"
}
