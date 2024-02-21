locals {
  ccm_version    = var.hetzner_ccm_version != null ? var.hetzner_ccm_version : data.github_release.hetzner_ccm[0].release_tag
  csi_version    = length(data.github_release.hetzner_csi) == 0 ? var.csi.hetzner_csi.version : data.github_release.hetzner_csi[0].release_tag
  kured_version  = var.automatic_updates.kured.version != null ? var.automatic_updates.kured.version : data.github_release.kured[0].release_tag
  calico_version = length(data.github_release.calico) == 0 ? var.cni.calico.version : data.github_release.calico[0].release_tag
}
