terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 4.0.0, < 5.0.0"
    }
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
