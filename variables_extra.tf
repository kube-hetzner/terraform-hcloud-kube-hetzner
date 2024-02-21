# Extra config (preinstall, postinstall, extra kustomize commands, extra kustomize parameters)
variable "extra" {
  type = object({
    ## Additional commands
    exec = optional(object({
      ### Additional commands to execute before the install calls, for example fetching and installing certs
      preinstall = optional(list(string), [])
      ### Additional commands to execute after the install calls, for example restoring a backup
      postinstall = optional(list(string), [])
    }), {})

    ## Additional kustomize commands
    kustomize = optional(object({
      ### Additional commands to execute after the `kubectl apply -k <dir>` step
      deployment_commands = optional(string, "")
      ### Additional parameters to pass to the `kustomization.tmp.yml` template
      parameters = optional(map(any), {})
    }), {})
  })

  default     = {}
  description = "Extra config (preinstall, postinstall, extra kustomize commands, extra kustomize parameters)"
}
