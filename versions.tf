terraform {
  required_version = ">= 1.5.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 5.38.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.43.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
    remote = {
      source  = "tenstad/remote"
      version = ">= 0.1.2"
    }
  }
}
