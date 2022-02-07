apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- "https://github.com/weaveworks/kured/releases/download/${version}/kured-${version}-dockerhub.yaml"

patchesStrategicMerge:
- patch.yaml