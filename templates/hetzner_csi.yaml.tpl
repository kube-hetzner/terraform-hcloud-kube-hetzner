apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- "https://raw.githubusercontent.com/hetznercloud/csi-driver/${csi_version}/deploy/kubernetes/hcloud-csi.yml"

%{ if patch_name != "" }
patchesStrategicMerge:
- ${patch_name}.yaml
%{ endif }