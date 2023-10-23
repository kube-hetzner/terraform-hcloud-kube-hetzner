---
apiVersion: v1
kind: Namespace
metadata:
  name: traefik
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: traefik
  namespace: kube-system
spec:
  chart: traefik
  version: v24.0.0
  repo: https://traefik.github.io/charts
  targetNamespace: traefik
  bootstrap: true
  valuesContent: |-
    ${values}