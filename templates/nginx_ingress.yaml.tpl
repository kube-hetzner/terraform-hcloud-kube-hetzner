---
apiVersion: v1
kind: Namespace
metadata:
  name: nginx
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: nginx
  namespace: kube-system
spec:
  chart: ingress-nginx
  repo: https://kubernetes.github.io/ingress-nginx
  targetNamespace: ${target_namespace}
  bootstrap: true
  valuesContent: |-
    ${values}
