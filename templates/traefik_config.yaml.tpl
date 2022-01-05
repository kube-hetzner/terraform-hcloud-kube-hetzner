apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    service:
      enabled: true
      type: LoadBalancer
      annotations:
        "load-balancer.hetzner.cloud/name": "traefik"
        "load-balancer.hetzner.cloud/use-private-ip": "true"
        "load-balancer.hetzner.cloud/location": "${location}"
        "load-balancer.hetzner.cloud/type": "${lb_server_type}"
        "load-balancer.hetzner.cloud/uses-proxyprotocol": "true"
    additionalArguments:
      - "--entryPoints.web.proxyProtocol.trustedIPs=127.0.0.1/32,10.0.0.0/8"
      - "--entryPoints.websecure.proxyProtocol.trustedIPs=127.0.0.1/32,10.0.0.0/8"
      - "--entryPoints.web.forwardedHeaders.trustedIPs=127.0.0.1/32,10.0.0.0/8"
      - "--entryPoints.websecure.forwardedHeaders.trustedIPs=127.0.0.1/32,10.0.0.0/8"