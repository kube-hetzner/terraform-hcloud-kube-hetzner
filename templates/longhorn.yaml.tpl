apiVersion: v1
kind: Namespace
metadata:
  name: longhorn-system
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: longhorn
  namespace: kube-system
spec:
  chart: longhorn-crd
  # Using this repo makes it compatible with Rancher
  repo: https://charts.rancher.io
  targetNamespace: longhorn-system
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: longhorn
  namespace: kube-system
spec:
  chart: longhorn
  # Using this repo makes it compatible with Rancher
  repo: https://charts.rancher.io
  targetNamespace: longhorn-system
  valuesContent: |-
    defaultSettings:
      defaultDataPath: /var/longhorn
    persistence:
      defaultFsType: ext4
      defaultClassReplicaCount: 3
      %{ if disable_hetzner_csi ~}defaultClass: true%{ else ~}defaultClass: false%{ endif ~}
