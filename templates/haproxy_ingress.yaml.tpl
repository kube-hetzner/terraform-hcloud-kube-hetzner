---
apiVersion: v1
kind: Namespace
metadata:
  name: ${target_namespace}
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: haproxy
  namespace: kube-system
spec:
  chart: kubernetes-ingress
  version: "${version}"
  repo: https://haproxytech.github.io/helm-charts
  targetNamespace: ${target_namespace}
  bootstrap: true
  valuesContent: |-
    ${values}
