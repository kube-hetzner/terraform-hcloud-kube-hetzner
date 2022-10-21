apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: ngx
  namespace: kube-system
spec:
  chart: ingress-nginx
  repo: https://kubernetes.github.io/ingress-nginx
  targetNamespace: kube-system
  bootstrap: true
  valuesContent: |-
    ${values}