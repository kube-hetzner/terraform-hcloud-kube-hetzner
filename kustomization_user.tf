locals {
  user_kustomization_exists = fileexists("extra-manifests/kustomization.yaml.tpl")
  user_kustomization_files  = toset([for p in fileset("extra-manifests", "**") : p if p != "kustomization.yaml.tpl"])
}

resource "null_resource" "kustomization_user" {
  count = local.user_kustomization_exists ? 1 : 0
  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port           = var.ssh_port
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Create kustomize dir'",
      "mkdir -p /var/user_kustomize"
    ]
  }

  provisioner "file" {
    source      = "extra-manifests/"
    destination = "/var/user_kustomize"
  }

  provisioner "file" {
    content     = templatefile("extra-manifests/kustomization.yaml.tpl", var.extra_kustomize_parameters)
    destination = "/var/user_kustomize/kustomization.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "rm /var/user_kustomize/kustomization.yaml.tpl",
      "kubectl apply -k /var/user_kustomize/"
    ]
  }


  depends_on = [
    null_resource.kustomization,
  ]
}
