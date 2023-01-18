---
apiVersion: v1
kind: Namespace
metadata:
  name: ${longhorn_namespace}
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: longhorn
  namespace: kube-system
spec:
  chart: longhorn
  repo: ${longhorn_repository}
  targetNamespace: ${longhorn_namespace}
  valuesContent: |-
    ${values}