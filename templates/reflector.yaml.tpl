apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: emberstack
  namespace: kube-system
spec:
  chart: reflector
  repo: https://emberstack.github.io/helm-charts
  valuesContent: |-
    ${values}
