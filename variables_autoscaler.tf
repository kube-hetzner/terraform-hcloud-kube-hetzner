# Cluster autoscaler config
variable "cluster_autoscaler" {
  type = object({
    ## Image of Kubernetes Cluster Autoscaler for Hetzner Cloud to be used
    image = optional(string, "ghcr.io/kube-hetzner/autoscaler/cluster-autoscaler")

    ## Version of Kubernetes Cluster Autoscaler for Hetzner Cloud
    ## Should be aligned with Kubernetes version
    version = optional(string, "20231027")

    ## Verbosity level of the logs for cluster-autoscaler
    log_level = optional(number, 4)

    ## Determines whether to log to stderr or not
    log_to_stderr = optional(bool, true)

    ## Severity level above which logs are sent to stderr instead of stdout
    stderr_threshold = optional(string, "INFO")

    ## Extra arguments for the Cluster Autoscaler deployment
    extra_args = optional(list(string), [])
  })

  validation {
    condition     = var.cluster_autoscaler.log_level >= 0 && var.cluster_autoscaler.log_level <= 5
    error_message = "The log level must be between 0 and 5."
  }

  validation {
    condition     = var.cluster_autoscaler.stderr_threshold == "INFO" || var.cluster_autoscaler.stderr_threshold == "WARNING" || var.cluster_autoscaler.stderr_threshold == "ERROR" || var.cluster_autoscaler.stderr_threshold == "FATAL"
    error_message = "The stderr threshold must be one of the following: INFO, WARNING, ERROR, FATAL."
  }

  default     = {}
  description = "Cluster autoscaler config"
}

# Autoscaler nodepools config
variable "autoscaler_nodes" {
  type = object({
    ## Cluster autoscaler nodepools
    nodepools = optional(list(object({
      name        = string
      server_type = string
      location    = string
      min_nodes   = number
      max_nodes   = number
      labels      = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])
    })), [])

    ## Labels for nodes created by the Cluster Autoscaler
    labels = optional(list(string), [])

    ## Taints for nodes created by the Cluster Autoscaler
    taints = optional(list(string), [])
  })
}
