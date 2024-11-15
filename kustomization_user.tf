locals {
  user_kustomization_templates = try(fileset("extra-manifests", "**/*.yaml.tpl"), toset([]))
}

moved {
  from = null_resource.kustomization_user
  to   = terraform_data.kustomization_user
}
resource "terraform_data" "kustomization_user" {
  for_each = local.user_kustomization_templates

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port           = var.ssh_port
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p $(dirname /var/user_kustomize/${each.key})"
    ]
  }

  provisioner "file" {
    content     = templatefile("extra-manifests/${each.key}", var.extra_kustomize_parameters)
    destination = replace("/var/user_kustomize/${each.key}", ".yaml.tpl", ".yaml")
  }

  triggers_replace = {
    manifest_sha1 = "${sha1(templatefile("extra-manifests/${each.key}", var.extra_kustomize_parameters))}"
  }

  depends_on = [
    terraform_data.kustomization
  ]
}

moved {
  from = null_resource.kustomization_user_deploy
  to   = terraform_data.kustomization_user_deploy
}
resource "terraform_data" "kustomization_user_deploy" {
  count = length(local.user_kustomization_templates) > 0 ? 1 : 0

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
    inline = compact([
      "rm -f /var/user_kustomize/**/*.yaml.tpl",
      "echo 'Applying user kustomization...'",
      "kubectl apply -k /var/user_kustomize/ --wait=true",
      var.extra_kustomize_deployment_commands
    ])
  }

  lifecycle {
    replace_triggered_by = [
      terraform_data.kustomization_user
    ]
  }

  depends_on = [
    terraform_data.kustomization_user
  ]
}
