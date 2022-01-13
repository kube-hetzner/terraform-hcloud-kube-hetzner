terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.0.0, < 2.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0, < 3.0.0"
    }
  }
}
