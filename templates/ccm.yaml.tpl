---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: hccm
  namespace: kube-system
spec:
  chart: hcloud-cloud-controller-manager
  repo: https://charts.hetzner.cloud
  version: "${version}"
  targetNamespace: kube-system
  bootstrap: true
  valuesContent: |-
    ${values}