locals {
  csi = {
    csi_driver_smb = {
      values = var.csi.csi_driver_smb.values != "" ? var.csi.csi_driver_smb.values : <<EOT
  EOT
    }

    longhorn = {
      values = var.csi.longhorn.values != "" ? var.csi.longhorn.values : <<EOT
defaultSettings:
%{if length(var.autoscaler_nodes.nodepools) != 0~}
  kubernetesClusterAutoscalerEnabled: true
%{endif~}
  defaultDataPath: /var/longhorn
persistence:
  defaultFsType: ${var.csi.longhorn.fstype}
  defaultClassReplicaCount: ${var.csi.longhorn.replica_count}
  %{if var.csi.hetzner_csi.enabled~}defaultClass: true%{else~}defaultClass: false%{endif~}
  EOT
    }
  }
}
