---
apiVersion: v1
kind: Namespace
metadata:
  name: system-longhorn
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
  targetNamespace: system-longhorn
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
  targetNamespace: system-longhorn
  valuesContent: |-
    ${values}