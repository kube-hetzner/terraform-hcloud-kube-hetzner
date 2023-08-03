resource "local_file" "kustomization_backup" {
  count           = var.create_kustomization ? 1 : 0
  content         = local.kustomization_backup_yaml
  filename        = "${var.cluster_name}_kustomization_backup.yaml"
  file_permission = "600"
}
