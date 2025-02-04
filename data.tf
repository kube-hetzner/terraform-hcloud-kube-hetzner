data "github_release" "hetzner_ccm" {
  count       = var.hetzner_ccm_version == null ? 1 : 0
  repository  = "hcloud-cloud-controller-manager"
  owner       = "hetznercloud"
  retrieve_by = "latest"
}

data "github_release" "hetzner_csi" {
  count       = var.hetzner_csi_version == null && !var.disable_hetzner_csi ? 1 : 0
  repository  = "csi-driver"
  owner       = "hetznercloud"
  retrieve_by = "latest"
}

// github_release for kured
data "github_release" "kured" {
  count       = var.kured_version == null ? 1 : 0
  repository  = "kured"
  owner       = "kubereboot"
  retrieve_by = "latest"
}

// github_release for kured
data "github_release" "calico" {
  count       = var.calico_version == null && var.cni_plugin == "calico" ? 1 : 0
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

data "hcloud_image" "microos_x86_snapshot" {
  count             = local.os_requirements.microos ? 1 : 0
  with_selector     = "microos-snapshot=yes"
  with_architecture = "x86"
  most_recent       = true
}

data "hcloud_image" "microos_arm_snapshot" {
  count             = local.os_requirements.microos ? 1 : 0
  with_selector     = "microos-snapshot=yes"
  with_architecture = "arm"
  most_recent       = true
}

data "hcloud_image" "leapmicro_x86_snapshot" {
  count             = local.os_requirements.leapmicro ? 1 : 0
  with_selector     = "leapmicro-snapshot=yes"
  with_architecture = "x86"
  most_recent       = true
}

data "hcloud_image" "leapmicro_arm_snapshot" {
  count             = local.os_requirements.leapmicro ? 1 : 0
  with_selector     = "leapmicro-snapshot=yes"
  with_architecture = "arm"
  most_recent       = true
}
