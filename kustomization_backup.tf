data "remote_file" "kustomization_backup" {
  conn {
    host        = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port        = var.ssh_port
    user        = "root"
    private_key = var.ssh_private_key
    agent       = var.ssh_private_key == null
  }
  path = "/var/post_install/kustomization.yaml"

  depends_on = [null_resource.kustomization]
}

resource "local_file" "kustomization_backup" {
  content         = data.remote_file.kustomization_backup.content
  filename        = "${var.cluster_name}_kustomization_backup.yaml"
  file_permission = "600"
}
