# How install deploy a additional / extra stuff while terraforming the cluster

## With a `HelmChart` and `HelmChartConfig`

This is how it worked for me, note I'm a total beginner with kustomize.<br>
Pretty sure I butchered a lot ;)

### Assuming you followed the `DO not Skip` part of the installation

In the project folder, where the `kube.tf` is located.<br>
Create a folder named `extra-manifests`<br>
In it create a file named `kustomization.yaml.tpl`<br>
and **your** manifest file(s), there names must be listed in the `kustomization.yaml.tpl` `recources` without the `.tpl`<br>
e.g. `some-random-name.yaml.tpl`

## Apply the kustomized configuration

Assuming no errors have been made, apply this by run `terraform apply`<br>

## ReRun the kustomization (debugging)

In the highly unlikely case that an actual error has occurred...<br>
Anyway, you can rerun just the kustomization part like this:

    terraform apply -replace='module.kube-hetzner.null_resource.kustomization_user["kustomization.yaml.tpl"]' --auto-approve

Check what kustomization exists:

    (⎈|dev3:default)➜ dev3-cluster (main) ✗ terraform state list | grep kustom
    ...
    module.kube-hetzner.null_resource.kustomization
    module.kube-hetzner.null_resource.kustomization_user["some-random-name.yaml.tpl"]
    module.kube-hetzner.null_resource.kustomization_user["kustomization.yaml.tpl"]
    ...
