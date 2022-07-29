apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cilium
  namespace: kube-system
spec:
  chart: cilium
  repo: https://helm.cilium.io/
  targetNamespace: kube-system
  bootstrap: true
  valuesContent: |-
    ipam:
      operator:
        clusterPoolIPv4PodCIDRList:
          - ${cluster_cidr_ipv4}