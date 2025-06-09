terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.51.0"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = ">= 2.7.0"
    }
  }
}
