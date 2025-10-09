# Purpose of this module is to initiate the copy of each user kustomization "set" and the deploy them one by one in sequential order.


module "user_kustomization_set" {
  source = "../user_kustomization_set"

  for_each = var.kustomizations_map

  ssh_connection = var.ssh_connection

  source_folder       = each.value.source_folder
  destination_folder  = "${local.base_destination_folder}/${each.key}"
  template_parameters = each.value.kustomize_parameters

  pre_commands_string  = each.value.pre_commands
  post_commands_string = each.value.post_commands
}

resource "null_resource" "kustomization_user_deploy" {

  triggers = {
    kustomization_shas = join("", [
      for key, mod in module.user_kustomization_set : mod.changes_sha
      ]
    )
  }

  connection {
    user           = var.ssh_connection.user
    private_key    = var.ssh_connection.private_key
    agent_identity = var.ssh_connection.agent_identity
    host           = var.ssh_connection.host
    port           = var.ssh_connection.port

    bastion_host        = var.ssh_connection.bastion_host
    bastion_port        = var.ssh_connection.bastion_port
    bastion_user        = var.ssh_connection.bastion_user
    bastion_private_key = var.ssh_connection.bastion_private_key
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      #!/bin/bash
      for dest_folder in ${join(" ", local.sorted_kustomization_destination_folders)}; do
        if [ -d "$dest_folder" ]; then
          echo "Running pre-install script from $dest_folder"
          /bin/bash "$dest_folder/preinstall.sh"

          if [ -f "$dest_folder/kustomization.yaml" ]; then
            echo "Applying kustomization from $dest_folder"
            kubectl apply -k "$dest_folder"
          else
            echo "No kustomization.yaml in $dest_folder, skipping apply."
          fi

          echo "Running post-install script from $dest_folder"
          /bin/bash "$dest_folder/postinstall.sh"
        fi
      done
      echo "Cleaning up ${local.base_destination_folder}..."
      rm -rf ${local.base_destination_folder}/*
      EOT
    ]
  }

  depends_on = [
    module.user_kustomization_set,
  ]
}

