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
        # make hetzners load-balancer connect to our nodes via our private k3s-net.
        "load-balancer.hetzner.cloud/use-private-ip": "true"
        # keep hetzner-ccm from exposing our private ingress ip, which in general isn't routeable from the public internet.
        "load-balancer.hetzner.cloud/disable-private-ingress": "true"
        # disable ipv6 by default, because external-dns doesn't support AAAA for hcloud yet https://github.com/kubernetes-sigs/external-dns/issues/2044
        "load-balancer.hetzner.cloud/ipv6-disabled": "${lb_disable_ipv6}"
        "load-balancer.hetzner.cloud/location": "${location}"
        "load-balancer.hetzner.cloud/type": "${lb_server_type}"
        "load-balancer.hetzner.cloud/uses-proxyprotocol": "true"
    additionalArguments:
      - "--entryPoints.web.proxyProtocol.trustedIPs=127.0.0.1/32,10.0.0.0/8"
      - "--entryPoints.websecure.proxyProtocol.trustedIPs=127.0.0.1/32,10.0.0.0/8"
      - "--entryPoints.web.forwardedHeaders.trustedIPs=127.0.0.1/32,10.0.0.0/8"
      - "--entryPoints.websecure.forwardedHeaders.trustedIPs=127.0.0.1/32,10.0.0.0/8"
%{ if traefik_acme_tls ~}
      - "--certificatesresolvers.le.acme.tlschallenge=true"
      - "--certificatesresolvers.le.acme.email=${traefik_acme_email}"
      - "--certificatesresolvers.le.acme.storage=/data/acme.json"
%{ endif ~}