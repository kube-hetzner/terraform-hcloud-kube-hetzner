apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- "https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/download/${ccm_version}/ccm-networks.yaml"

patchesStrategicMerge:
- patch.yaml
