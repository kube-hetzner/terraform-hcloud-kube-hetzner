terraform {
  required_version = ">= 1.4.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 4.0.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.41.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
    remote = {
      source  = "tenstad/remote"
      version = ">= 0.0.23"
    }
  }
}
