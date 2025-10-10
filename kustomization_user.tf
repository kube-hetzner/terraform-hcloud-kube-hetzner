locals {
  default_user_kustomize = {
    "1" = {
      source_folder        = "extra-manifests-preinstall"
      kustomize_parameters = {}
      pre_commands         = ""
      post_commands        = ""
    },
    "2" = {
      source_folder        = var.extra_kustomize_folder
      kustomize_parameters = var.extra_kustomize_parameters
      pre_commands         = ""
      post_commands        = var.extra_kustomize_deployment_commands
    }
  }

  user_kustomize_defaulted = length(var.user_kustomizations) > 0 ? var.user_kustomizations : local.default_user_kustomize

  processed_kustomizes = {
    for key, config in local.user_kustomize_defaulted : key => {
      # kustomize_parameters may contain secrets
      kustomize_parameters = sensitive(config.kustomize_parameters)
      source_folder        = config.source_folder
      pre_commands         = config.pre_commands
      post_commands        = config.post_commands
    }
  }
}

module "user_kustomizations" {

  source = "./modules/user_kustomizations"

  ssh_connection = {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = local.first_control_plane_ip
    port           = var.ssh_port

    bastion_host        = local.ssh_bastion.bastion_host
    bastion_port        = local.ssh_bastion.bastion_port
    bastion_user        = local.ssh_bastion.bastion_user
    bastion_private_key = local.ssh_bastion.bastion_private_key
  }

  kustomizations_map = local.processed_kustomizes

  depends_on = [
    null_resource.kustomization,
  ]
}
