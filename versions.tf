terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 4.0.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
    remote = {
      source  = "tenstad/remote"
      version = ">= 0.0.23"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 1.23.0"
    }
  }
}
