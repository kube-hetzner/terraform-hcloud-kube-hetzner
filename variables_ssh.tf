# SSH config
variable "ssh" {
  type = object({
    ## The main SSH port to connect to the nodes
    port = optional(number, 22)

    ## Public SSH key
    #! Required option, so no default value is set
    public_key = string

    ## Additional SSH public keys
    ## Use them to grant other team members root access to your cluster nodes
    additional_public_keys = optional(list(string), [])

    ## Additional SSH public keys by hcloud label
    ## example: role=admin
    hcloud_key_label = optional(string, "")

    ## Key already registered within Hetzner
    ## Otherwise, a new one will be created by the module
    hcloud_ssh_key_id = optional(string, null)

    ## The maximum number of authentication attempts permitted per connection
    max_auth_tries = optional(number, 2)
  })

  validation {
    condition     = var.ssh.port >= 0 && var.ssh.port <= 65535
    error_message = "The SSH port must be in a valid range from 0 to 65535."
  }

  #! There are required options, so no default value is set
  description = "SSH config"
}
