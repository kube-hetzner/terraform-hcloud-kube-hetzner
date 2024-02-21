# Network config (region, cidr, dns)
variable "network" {
  type = object({
    ## Default region for the Hetzner network
    ## WARNING: Node locations must be in the same region as the network
    region = optional(string, "eu-central")

    ## IPv4 and IPv6 CIDR blocks for the network
    cidr_blocks = optional(object({
      ### IPv4 CIDR blocks for the network
      ipv4 = optional(object({
        #### The main network cidr that all subnets will be created upon
        main = optional(string, "10.0.0.0/8")

        #### Internal Pod CIDR, used for the controller and currently for calico/cilium
        cluster = optional(string, "10.42.0.0/16")

        #### Internal Service CIDR, used for the controller and currently for calico/cilium
        service = optional(string, "10.43.0.0/16")
      }), {})

      ### IPv6 CIDR blocks for the network
      ### WARNING: Internal IPv6 is not yet supported, but we still provide the option to configure it
      ipv6 = optional(object({
        #### The main network cidr that all subnets will be created upon
        main = optional(string)

        #### Internal Pod CIDR, used for the controller and currently for calico/cilium
        cluster = optional(string)

        #### Internal Service CIDR, used for the controller and currently for calico/cilium
        service = optional(string)
      }), {})
    }), {})

    ## Internal Service IPv4 address of core-dns
    cluster_dns = optional(object({
      ### IPv4 address of the core-dns service
      ipv4 = optional(string, "10.43.0.10")

      ### IPv6 address of the core-dns service
      ### WARNING: Internal IPv6 is not yet supported, but we still provide the option to configure it
      ipv6 = optional(string)
    }), {})

    ## IP Addresses to use for the DNS Servers, set by default to use the ones provided by Hetzner
    ## WARNING: The length is limited to 3 entries, the maximum supported by K8s
    dns_servers = optional(list(string), [
      "185.12.64.1",
      "185.12.64.2",
      "2a01:4ff:ff00::add:1",
    ])

    ## Before installing k3s, we actually verify that there is internet connectivity
    ## By default we ping 1.1.1.1, but if you use a proxy, you may simply want to ping that proxy instead
    ## Assuming that the proxy has its own checks for internet connectivity
    internet_check_address = optional(string, "1.1.1.1")

    ## Unfortunately, we need this to be a list or null. If we only use a plain
    ## string here, and check that existing_network_id is null, terraform
    ## will complain that it cannot set `count` variables based on
    ## existing_network_id != null, because that id is an output value from
    ## hcloud_network.your_network.id, which terraform will only know
    ## after its construction.
    existing_network_id = optional(list(string), [])
  })

  validation {
    condition     = length(var.network.dns_servers) <= 3
    error_message = "The list must have no more than 3 items."
  }

  ## nullable = false
  validation {
    condition     = var.network.existing_network_id != null && (length(var.network.existing_network_id) == 0 || (can(var.network.existing_network_id[0]) && length(var.network.existing_network_id) == 1))
    error_message = "If you pass an existing_network_id, it must be enclosed in square brackets: [id]. This is necessary to be able to unambiguously distinguish between an empty network id (default) and a user-supplied network id."
  }

  default     = {}
  description = "Network config (region, cidr, dns)"
}
