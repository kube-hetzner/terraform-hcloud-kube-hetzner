data "github_release" "hetzner_ccm" {
  repository  = "hcloud-cloud-controller-manager"
  owner       = "hetznercloud"
  retrieve_by = "latest"
}

data "github_release" "hetzner_csi" {
  repository  = "csi-driver"
  owner       = "hetznercloud"
  retrieve_by = "latest"
}

data "hcloud_image" "linux" {
  name = local.hcloud_image_name
}
