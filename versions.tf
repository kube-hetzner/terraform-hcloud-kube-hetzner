terraform {
  required_version = ">= 1.8.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.4.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.51.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.2"
    }
    remote = {
      source  = "tenstad/remote"
      version = ">= 0.1.3"
    }
    assert = {
      source  = "hashicorp/assert"
      version = ">= 0.16.0"
    }
  }
}
