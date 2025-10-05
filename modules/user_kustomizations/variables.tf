variable "ssh_connection" {
  type = object({
    user           = string
    private_key    = string
    agent_identity = string
    host           = string
    port           = string

    bastion_host        = string
    bastion_port        = number
    bastion_user        = string
    bastion_private_key = string
  })
  sensitive = true
}

variable "kustomizations_map" {
  type = map(object({
    source_folder        = string
    kustomize_parameters = map(any)
    post_commands        = string
  }))
  default     = {}
  description = "Map of kustomization entries, where key is the order number."
  validation {
    condition = alltrue([
      for key in keys(var.kustomizations_map) :
      tonumber(key) > 0 && floor(tonumber(key)) == tonumber(key) && can(regex("^[0-9]+$", key))
    ])
    error_message = "All keys in kustomizations_map must be numeric strings (e.g., '1', '2')."
  }
}
