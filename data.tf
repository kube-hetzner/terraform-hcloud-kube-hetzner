data "github_release" "hetzner_ccm" {
  count       = var.hetzner_ccm_version == null ? 1 : 0
  repository  = "hcloud-cloud-controller-manager"
  owner       = "hetznercloud"
  retrieve_by = "latest"
}

data "github_release" "hetzner_csi" {
  count       = var.csi.hetzner_csi.version == null && var.csi.hetzner_csi.enabled ? 1 : 0
  repository  = "csi-driver"
  owner       = "hetznercloud"
  retrieve_by = "latest"
}

// github_release for kured
data "github_release" "kured" {
  count       = var.automatic_updates.kured.version == null ? 1 : 0
  repository  = "kured"
  owner       = "kubereboot"
  retrieve_by = "latest"
}

// github_release for kured
data "github_release" "calico" {
  count       = var.cni.calico.version == null && var.cni.type == "calico" ? 1 : 0
  repository  = "calico"
  owner       = "projectcalico"
  retrieve_by = "latest"
}

# data "hcloud_load_balancer" "cluster" {
#   count = local.has_external_load_balancer ? 0 : 1
#   name  = var.cluster_name

#   depends_on = [null_resource.kustomization]
# }

data "hcloud_ssh_keys" "keys_by_selector" {
  count         = length(var.ssh_hcloud_key_label) > 0 ? 1 : 0
  with_selector = var.ssh_hcloud_key_label
}
