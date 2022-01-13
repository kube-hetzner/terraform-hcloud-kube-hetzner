provider "github" {}

provider "hcloud" {
  token = var.hcloud_token
}

provider "local" {}
