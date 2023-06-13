locals {
  user_kustomization_templates = fileset("extra-manifests", "*.yaml.tpl")
}

resource "null_resource" "kustomization_user_setup" {
  count = length(local.user_kustomization_templates) > 0 ? 1 : 0

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port           = var.ssh_port
  }

  # Create remote directory
  provisioner "remote-exec" {
    inline = [
      "echo 'Create new /var/user_kustomize directory...'",
      "rm -rf /var/user_kustomize && mkdir -p /var/user_kustomize"
    ]
  }

  # Copy all files, recursively from extra-manifests/ into the /var/user_kustomize directory.
  # NOTE: If non *.yaml.tpl files are changed, you need to taint this resource to re-provision the changes,
  # since there is no 'triggers {}' definition that watches all files/directories for changes.
  provisioner "file" {
    source      = "extra-manifests/"
    destination = "/var/user_kustomize"
  }

  depends_on = [
    null_resource.kustomization
  ]
}

resource "null_resource" "kustomization_user" {
  for_each = local.user_kustomization_templates

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port           = var.ssh_port
  }

  provisioner "file" {
    content     = templatefile("extra-manifests/${each.key}", var.extra_kustomize_parameters)
    destination = replace("/var/user_kustomize/${each.key}", ".yaml.tpl", ".yaml")
  }

  triggers = {
    manifest_sha1 = "${sha1(templatefile("extra-manifests/${each.key}", var.extra_kustomize_parameters))}"
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.kustomization_user_setup
    ]
  }

  depends_on = [
    null_resource.kustomization_user_setup[0]
  ]
}

resource "null_resource" "kustomization_user_deploy" {
  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port           = var.ssh_port
  }

  # Remove templates after rendering, and apply changes.
  provisioner "remote-exec" {
    # Debugging: "sh -c 'for file in $(find /var/user_kustomize -type f -name \"*.yaml\" | sort -n); do echo \"\n### Template $${file}.tpl after rendering:\" && cat $${file}; done'",
    inline = [
      "rm -f /var/user_kustomize/*.yaml.tpl",
      "echo 'Deploying manifests from /var/user_kustomize/:' && ls -alh /var/user_kustomize",
      "kubectl kustomize /var/user_kustomize/ | kubectl apply --wait=true -f -",
      "${var.extra_kustomize_deployment_commands}"
    ]
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.kustomization_user
    ]
  }

  depends_on = [
    null_resource.kustomization_user
  ]
}
