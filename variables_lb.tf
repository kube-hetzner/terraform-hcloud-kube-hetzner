# Load balancer config
variable "load_balancer" {
  type = object({
    ## Ingress load balancer
    ingress = optional(object({
      ### When enabled, the ingress controller will be exposed via a load balancer
      enabled = optional(bool, true)

      ### The type of load balancer to use for the ingress load balancer (klipper or lbXY from Hetzner)
      type = optional(string, "lb11")

      ### The location of the load balancer
      location = optional(string, "fsn1")

      ### The algorithm of the load balancer
      algorithm = optional(string, "least_connections")

      ### The interval at which a health check is performed
      ### Minimum is 3s
      health_check_interval = optional(string, "15s")

      ### The timeout of a single health check
      ### Must not be greater than the health check interval
      ### Minimum is 1s
      health_check_timeout = optional(string, "10s")

      ### The number of times a health check is retried before a target is marked as unhealthy
      health_check_retries = optional(number, 3)

      ### The hostname of the load balancer
      hostname = optional(string, "")

      ### Disable IPv6 for the load balancer
      disable_ipv6 = optional(bool, true)

      ### Disable public network of the load balancer
      disable_public_network = optional(bool, true)
    }), {})

    ## Kubernetes API load balancer
    kubeapi = optional(object({
      ### When enabled, the Kubernetes API server will be exposed via a load balancer
      ### This is only needed if external services need HA access to the Kubernetes API
      enabled = optional(bool, false)

      ### The type of load balancer to use for the ingress load balancer
      type = optional(string, "lb11")

      ### The location of the load balancer
      location = optional(string, "fsn1")

      ### The algorithm of the load balancer
      algorithm = optional(string, "least_connections")

      ### The interval at which a health check is performed
      ### Minimum is 3s
      health_check_interval = optional(string, "15s")

      ### The timeout of a single health check
      ### Must not be greater than the health check interval
      ### Minimum is 1s
      health_check_timeout = optional(string, "10s")

      ### The number of times a health check is retried before a target is marked as unhealthy
      health_check_retries = optional(number, 3)

      ### The hostname of the load balancer
      hostname = optional(string, "")

      ### Disable IPv6 for the load balancer
      disable_ipv6 = optional(bool, true)

      ### Disable public network of the load balancer
      disable_public_network = optional(bool, true)
    }), {})
  })

  ## Ingress load balancer validation
  ### Check if type is klipper or lbXY
  validation {
    condition     = var.load_balancer.ingress.type == "klipper" || can(regex("lb\\d\\d", var.load_balancer.ingress.type))
    error_message = "The algorithm must be either \"least_connections\" or \"round_robin\"."
  }

  ### Check if algorithm is least_connections or round_robin
  validation {
    condition     = contains(["least_connections", "round_robin"], var.load_balancer.ingress.algorithm)
    error_message = "The type must be either \"klipper\" or \"lbXY\" format."
  }

  ### Check if hostname is FQDN
  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.load_balancer.ingress.hostname)) || var.load_balancer.ingress.hostname == ""
    error_message = "The hostname of the load balancer must be a valid domain name (FQDN)."
  }

  ## Kubernetes API load balancer validation
  ### Check if type is lbXY
  validation {
    condition     = can(regex("lb\\d\\d", var.load_balancer.kubeapi.type))
    error_message = "The type must be \"lbXY\" format."
  }

  ### Check if algorithm is least_connections or round_robin
  validation {
    condition     = contains(["least_connections", "round_robin"], var.load_balancer.kubeapi.algorithm)
    error_message = "The algorithm must be either \"least_connections\" or \"round_robin\"."
  }

  ### Check if hostname is FQDN
  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.load_balancer.kubeapi.hostname)) || var.load_balancer.kubeapi.hostname == ""
    error_message = "The hostname of the load balancer must be a valid domain name (FQDN)."
  }

  default     = {}
  description = "Load balancer config"
}
