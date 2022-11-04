apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  failurePolicy: abort
  valuesContent: |-
    ${values}