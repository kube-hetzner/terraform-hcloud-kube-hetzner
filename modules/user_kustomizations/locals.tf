locals {
  sorted_kustomization_destination_folders = [
    for idx in sort([
      for key, mod in module.user_kustomization_set : tonumber(key) if mod.files_count > 0
    ]) :
    module.user_kustomization_set[tostring(idx)].destination_folder
  ]
  base_destination_folder = "/var/user_kustomize"
}
