---
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cert-manager
  namespace: kube-system
spec:
  chart: cert-manager
  repo: https://charts.jetstack.io
  version: "${version}"
  targetNamespace: cert-manager
  bootstrap: ${bootstrap}
  valuesContent: |-
    ${values}
