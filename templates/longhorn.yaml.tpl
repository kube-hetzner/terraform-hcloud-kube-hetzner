---
apiVersion: v1
kind: Namespace
metadata:
  name: ${longhorn_namespace}
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: longhorn-crd
  namespace: kube-system
spec:
  chart: longhorn-crd
  # Using this repo makes it compatible with Rancher
  repo: https://charts.rancher.io
  targetNamespace: ${longhorn_namespace}
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: longhorn
  namespace: kube-system
spec:
  chart: longhorn
  # Using this repo makes it compatible with Rancher
  repo: https://charts.rancher.io
  targetNamespace: ${longhorn_namespace}
  valuesContent: |-
    ${values}