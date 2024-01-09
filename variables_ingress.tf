# Ingress controller config (traefik, nginx)
variable "ingress" {
  type = object({
    ## Type of the ingress controller (traefik, nginx, none)
    type = optional(string, "traefik")

    ## Number of replicas per ingress controller
    ## 0 means autodetect based on the number of agent nodes
    replica_count = optional(number, 0)

    ## Number of maximum replicas per ingress controller
    ## Used for ingress HPA
    ## Must be higher than replica_count
    max_replica_count = optional(number, 10)

    ## The namespace to deploy the ingress controller to. Defaults to ingress name.
    namespace = optional(string, "")

    ## Nginx config
    nginx = optional(object({
      ### Version of Nginx helm chart
      helm_chart_version = optional(string, "")

      ### Additional helm values file to pass to nginx as 'valuesContent' at the HelmChart.
      values = optional(string, "")
    }), {})

    ## Traefik config
    traefik = optional(object({
      ### Version of Traefik helm chart
      helm_chart_version = optional(string, "")

      ### Useful to use the beta version for new features
      ### Example: v3.0.0-beta5
      image_tag = optional(string, "")

      ### Redirect HTTP traffic to HTTPS
      redirect_to_https = optional(bool, true)

      ### Additional options to pass to Traefik as a list of strings
      ### These are the ones that go into the additionalArguments section of the Traefik helm values file
      additional_options = optional(list(string), [])

      ### Additional Trusted IPs to pass to Traefik
      ### These are the ones that go into the trustedIPs section of the Traefik helm values file
      additional_trusted_ips = optional(list(string), [])

      ### Additional ports to pass to Traefik
      ### These are the ones that go into the ports section of the Traefik helm values file
      additional_ports = optional(list(object({
        name        = string
        port        = number
        exposedPort = number
      })), [])

      ### Additional helm values file to pass to Traefik as 'valuesContent' at the HelmChart
      values = optional(string, "")
    }), {})
  })

  validation {
    condition     = contains(["traefik", "nginx", "none"], var.ingress.type)
    error_message = "Must be one of \"traefik\" or \"nginx\" or \"none\""
  }

  validation {
    condition     = var.ingress.replica_count >= 0
    error_message = "Number of ingress replicas can't be below 0."
  }

  validation {
    condition     = var.ingress.max_replica_count >= var.ingress.replica_count
    error_message = "Number of ingress maximum replicas can't be lower than replica_count."
  }

  default     = {}
  description = "Ingress controller config (traefik, nginx)"
}

# cert-manager config
variable "cert_manager" {
  type = object({
    ## Enable cert-manager
    enabled = optional(bool, true)

    ## Additional helm values file to pass to Cert-Manager as 'valuesContent' at the HelmChart
    values = optional(string, "")
  })

  default     = {}
  description = "cert-manager config"
}
