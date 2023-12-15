---
apiVersion: v1
kind: Namespace
metadata:
  name: ${target_namespace}
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: nginx
  namespace: kube-system
spec:
  chart: ingress-nginx
  version: "${version}"
  repo: https://kubernetes.github.io/ingress-nginx
  targetNamespace: ${target_namespace}
  bootstrap: true
  valuesContent: |-
    ${values}
