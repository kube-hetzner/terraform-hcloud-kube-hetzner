locals {
  kustomization_backup_yaml = yamlencode({
    apiVersion = "kustomize.config.k8s.io/v1beta1"
    kind       = "Kustomization"

    resources = concat(
      [
        "https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/download/${local.ccm_version}/ccm-networks.yaml",
        "https://github.com/kubereboot/kured/releases/download/${local.kured_version}/kured-${local.kured_version}-dockerhub.yaml",
        "https://raw.githubusercontent.com/rancher/system-upgrade-controller/master/manifests/system-upgrade-controller.yaml",
      ],
      var.csi.hetzner_csi.enabled ? ["hcloud-csi.yml"] : [],
      lookup(local.ingress_controller_install_resources, var.ingress.type, []),
      lookup(local.cni_install_resources, var.cni.type, []),
      var.csi.longhorn.enabled ? ["longhorn.yaml"] : [],
      var.csi.csi_driver_smb.enabled ? ["csi-driver-smb.yaml"] : [],
      var.cert_manager.enabled || var.rancher.enabled ? ["cert_manager.yaml"] : [],
      var.rancher.enabled ? ["rancher.yaml"] : [],
      var.rancher_registration_manifest_url != "" ? [var.rancher_registration_manifest_url] : []
    ),
    patches = [
      {
        target = {
          group     = "apps"
          version   = "v1"
          kind      = "Deployment"
          name      = "system-upgrade-controller"
          namespace = "system-upgrade"
        }
        patch = file("${path.module}/kustomize/system-upgrade-controller.yaml")
      },
      {
        path = "kured.yaml"
      },
      {
        path = "ccm.yaml"
      }
    ]
  })
}
