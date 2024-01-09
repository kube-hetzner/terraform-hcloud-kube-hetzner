resource "local_file" "cilium_values" {
  count           = var.export_values && var.cni.type == "cilium" ? 1 : 0
  content         = local.cilium_values
  filename        = "cilium_values.yaml"
  file_permission = "600"
}

resource "local_file" "cert_manager_values" {
  count           = var.export_values && var.cert_manager.enabled ? 1 : 0
  content         = local.cert_manager_values
  filename        = "cert_manager_values.yaml"
  file_permission = "600"
}

resource "local_file" "csi_driver_smb_values" {
  count           = var.export_values && var.csi.csi_driver_smb.enabled ? 1 : 0
  content         = local.csi_driver_smb_values
  filename        = "csi_driver_smb_values.yaml"
  file_permission = "600"
}

resource "local_file" "longhorn_values" {
  count           = var.export_values && var.csi.longhorn.enabled ? 1 : 0
  content         = local.longhorn_values
  filename        = "longhorn_values.yaml"
  file_permission = "600"
}

resource "local_file" "traefik_values" {
  count           = var.export_values && var.ingress.type == "traefik" ? 1 : 0
  content         = local.traefik_values
  filename        = "traefik_values.yaml"
  file_permission = "600"
}

resource "local_file" "nginx_values" {
  count           = var.export_values && var.ingress.type == "nginx" ? 1 : 0
  content         = local.nginx_values
  filename        = "nginx_values.yaml"
  file_permission = "600"
}
