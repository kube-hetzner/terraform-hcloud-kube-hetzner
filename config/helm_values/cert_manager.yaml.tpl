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
  targetNamespace: cert-manager
  valuesContent: |-
    installCRDs: true

    ${values}

    replicaCount: 3

    webhook:
      replicaCount: 3

    cainjector:
      replicaCount: 3