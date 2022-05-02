---
apiVersion: v1
kind: Namespace
metadata:
  name: longhorn
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: longhorn
  namespace: kube-system
spec:
  chart: longhorn
  repo: https://charts.longhorn.io
  targetNamespace: longhorn
  valuesContent: |-
    defaultSettings:
      defaultDataPath: /var/longhorn
    persistence:
      defaultFsType: ext4
      defaultClassReplicaCount: 2
      %{ if disable_hetzner_csi ~}defaultClass: true%{ else ~}defaultClass: false%{ endif ~}
