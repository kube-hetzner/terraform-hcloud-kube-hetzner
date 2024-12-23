terraform {
  required_version = ">= 1.5.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.4.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.49.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.2"
    }
    remote = {
      source  = "tenstad/remote"
      version = ">= 0.1.3"
    }
  }
}
