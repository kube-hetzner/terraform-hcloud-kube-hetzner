---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: hcloud-cloud-controller-manager
  namespace: kube-system
spec:
  chart: hcloud-cloud-controller-manager
  repo: https://charts.hetzner.cloud
  version: "${version}"
  targetNamespace: kube-system
  bootstrap: true
  valuesContent: |-
    networking:
      enabled: "true"
    args:
      cloud-provider: hcloud
      allow-untagged-cloud: ""
      route-reconciliation-period: 30s
      webhook-secure-port: "0"
      ${using_klipper_lb ? "secure-port: \"10288\"" : ""}
    env:
      HCLOUD_LOAD_BALANCERS_LOCATION:
        value: "${default_lb_location}"
      HCLOUD_LOAD_BALANCERS_USE_PRIVATE_IP:
        value: "true"
      HCLOUD_LOAD_BALANCERS_ENABLED:
        value: "${!using_klipper_lb}"
      HCLOUD_LOAD_BALANCERS_DISABLE_PRIVATE_INGRESS:
        value: "true"