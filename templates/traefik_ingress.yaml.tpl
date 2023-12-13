---
apiVersion: v1
kind: Namespace
metadata:
  name: ${target_namespace}
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: traefik
  namespace: kube-system
spec:
  chart: traefik
  version: "${version}"
  repo: https://traefik.github.io/charts
  targetNamespace: ${target_namespace}
  bootstrap: true
  valuesContent: |-
    ${values}
