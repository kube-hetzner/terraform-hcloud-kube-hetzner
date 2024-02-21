# k3s config
variable "k3s" {
  type = object({
    ## Version of k3s to install
    version = optional(string, "v1.28")

    ## The control plane is started with `k3s server {k3s_exec_server_args}`
    ## Use this to add kube-apiserver-arg for example
    exec_server_args = optional(string, "")

    ## Agents nodes are started with `k3s agent {k3s_exec_agent_args}`
    ## Use this to add kubelet-arg for example
    exec_agent_args = optional(string, "")

    ## Additional environment variables for the k3s binary
    ## See for example https://docs.k3s.io/advanced#configuring-an-http-proxy
    additional_environment = optional(map(any), {})

    ## K3s registries.yml contents
    ## It used to access private docker registries
    registries = optional(string, "")
  })

  validation {
    condition     = contains(["stable", "latest", "testing"], var.k3s.version) || can(regex("v\\d\\.\\d(\\.\\d)?", var.k3s.version))
    error_message = "The version of k3s must \"stable\", \"latest\", \"testing\" or any k3s version listed in semver format (vX.Y.Z), patch field is optional."
  }

  default     = {}
  description = "k3s config"
}
