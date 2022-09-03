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

// github_release for kured
data "github_release" "kured" {
  repository  = "kured"
  owner       = "weaveworks"
  retrieve_by = "latest"
}

data "hcloud_load_balancer" "cluster" {
  count = local.using_klipper_lb ? 0 : local.ingress_controller == "none" ? 0 : 1
  name  = var.cluster_name

  depends_on = [null_resource.kustomization]
}
