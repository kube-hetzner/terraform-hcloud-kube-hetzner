# How install deploy a additional / extra stuff while terraforming the cluster

## With `extra_kustomize_deployment_commands`, a `HelmChart` and `HelmChartConfig`

This is how it worked for me, note I'm a total beginner with kustomize.<br>
Pretty sure I butchered a lot ;)

### Assuming you followed the `DO not Skip` part of the installation

In the project folder, where the `kube.tf` is located.<br>
Create a folder named `extra-manifests`<br>
In it create a file named `kustomization.yaml.tpl`<br>
and **your** manifest file(s), there names must be listed in the `kustomization.yaml.tpl` `recources` without the `.tpl`<br>
e.g. `some-random-name.yaml.tpl`

### In your `kube.tf`

Uncomment the line `# extra_kustomize_deployment_commands...`<br>
For one item do it like

    extra_kustomize_deployment_commands = "kubectl apply -f /var/user_kustomize/some-random-name.yaml"

The `/var/user_kustomize/` part is required and hardcoded aka just use it.<br>
But without the `.tpl`

For multiple items add them like this

    # Extra commands to be executed after the `kubectl apply -k` (useful for post-install actions, e.g. wait for CRD, apply additional manifests, etc.).
    extra_kustomize_deployment_commands = <<-EOT
      kubectl apply -f /var/user_kustomize/some-random-name.yaml
      kubectl apply -f /var/user_kustomize/cert-manager-webhook-inwx.yaml
    EOT
    # Extra values that will be passed to the `extra-manifests/kustomization.yaml.tpl` if its present.

Pretty sure they all have to be listed in the `kustomization.yaml.tpl` file under `recourses`

Note the `EOT` thing is called `heredoc`, google it.<br>


## Apply the kustomized configuration

Assuming no errors have been made, apply this by run `terraform apply`<br>

## ReRun the kustomization (debugging)

In the highly unlikely case that an actual error has occurred...<br>
Anyway, you can rerun just the kustomization part like this:

    (⎈|dev3:default)➜ dev3-cluster (main) ✗ terraform state list | grep kustom
    ...
    module.kube-hetzner.null_resource.kustomization
    module.kube-hetzner.null_resource.kustomization_user["some-random-name.yaml.tpl"]
    module.kube-hetzner.null_resource.kustomization_user["kustomization.yaml.tpl"]
    ...
    (⎈|dev3:default)➜ dev3-cluster (main) ✗ terraform apply -replace='module.kube-hetzner.null_resource.kustomization_user["some-random-name.yaml.tpl"]' --auto-approve
