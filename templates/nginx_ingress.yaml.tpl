apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: ngx
  namespace: kube-system
spec:
  chart: nginx-ingress
  repo: https://helm.nginx.com/stable
  targetNamespace: kube-system
  bootstrap: true
  valuesContent: |-
    ${values}