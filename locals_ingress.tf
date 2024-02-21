locals {
  cert_manager_values = var.cert_manager.values != "" ? var.cert_manager.values : <<EOT
installCRDs: true
  EOT

  nginx_values = var.ingress.nginx.values != "" ? var.ingress.nginx.values : <<EOT
controller:
  watchIngressWithoutClass: "true"
  kind: "Deployment"
  replicaCount: ${local.ingress_replica_count}
  config:
    "use-forwarded-headers": "true"
    "compute-full-forwarded-for": "true"
    "use-proxy-protocol": "${!local.using_klipper_lb}"
%{if !local.using_klipper_lb~}
  service:
    annotations:
      "load-balancer.hetzner.cloud/name": "${local.load_balancer_name}"
      "load-balancer.hetzner.cloud/use-private-ip": "true"
      "load-balancer.hetzner.cloud/disable-private-ingress": "true"
      "load-balancer.hetzner.cloud/disable-public-network": "${var.load_balancer.ingress.disable_public_network}"
      "load-balancer.hetzner.cloud/ipv6-disabled": "${var.load_balancer.ingress.disable_ipv6}"
      "load-balancer.hetzner.cloud/location": "${var.load_balancer.ingress.location}"
      "load-balancer.hetzner.cloud/type": "${var.load_balancer.ingress.type}"
      "load-balancer.hetzner.cloud/uses-proxyprotocol": "${!local.using_klipper_lb}"
      "load-balancer.hetzner.cloud/algorithm-type": "${var.load_balancer.ingress.algorithm}"
      "load-balancer.hetzner.cloud/health-check-interval": "${var.load_balancer.ingress.health_check_interval}"
      "load-balancer.hetzner.cloud/health-check-timeout": "${var.load_balancer.ingress.health_check_timeout}"
      "load-balancer.hetzner.cloud/health-check-retries": "${var.load_balancer.ingress.health_check_retries}"
%{if var.load_balancer.ingress.hostname != ""~}
      "load-balancer.hetzner.cloud/hostname": "${var.load_balancer.ingress.hostname}"
%{endif~}
%{endif~}
  EOT

  traefik_values = var.ingress.traefik.values != "" ? var.ingress.traefik.values : <<EOT
image:
  tag: ${var.ingress.traefik.image_tag}
deployment:
  replicas: ${local.ingress_replica_count}
globalArguments: []
service:
  enabled: true
  type: LoadBalancer
%{if !local.using_klipper_lb~}
  annotations:
    "load-balancer.hetzner.cloud/name": "${local.load_balancer_name}"
    "load-balancer.hetzner.cloud/use-private-ip": "true"
    "load-balancer.hetzner.cloud/disable-private-ingress": "true"
    "load-balancer.hetzner.cloud/disable-public-network": "${var.load_balancer.ingress.disable_public_network}"
    "load-balancer.hetzner.cloud/ipv6-disabled": "${var.load_balancer.ingress.disable_ipv6}"
    "load-balancer.hetzner.cloud/location": "${var.load_balancer.ingress.location}"
    "load-balancer.hetzner.cloud/type": "${var.load_balancer.ingress.type}"
    "load-balancer.hetzner.cloud/uses-proxyprotocol": "${!local.using_klipper_lb}"
    "load-balancer.hetzner.cloud/algorithm-type": "${var.load_balancer.ingress.algorithm}"
    "load-balancer.hetzner.cloud/health-check-interval": "${var.load_balancer.ingress.health_check_interval}"
    "load-balancer.hetzner.cloud/health-check-timeout": "${var.load_balancer.ingress.health_check_timeout}"
    "load-balancer.hetzner.cloud/health-check-retries": "${var.load_balancer.ingress.health_check_retries}"
%{if var.load_balancer.ingress.hostname != ""~}
    "load-balancer.hetzner.cloud/hostname": "${var.load_balancer.ingress.hostname}"
%{endif~}
%{endif~}
ports:
  web:
%{if var.ingress.traefik.redirect_to_https~}
    redirectTo:
      port: websecure
      priority: 10
%{endif~}
%{if !local.using_klipper_lb~}
    proxyProtocol:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
%{for ip in var.ingress.traefik.additional_trusted_ips~}
        - "${ip}"
%{endfor~}
    forwardedHeaders:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
%{for ip in var.ingress.traefik.additional_trusted_ips~}
        - "${ip}"
%{endfor~}
  websecure:
    proxyProtocol:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
%{for ip in var.ingress.traefik.additional_trusted_ips~}
        - "${ip}"
%{endfor~}
    forwardedHeaders:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
%{for ip in var.ingress.traefik.additional_trusted_ips~}
        - "${ip}"
%{endfor~}
%{endif~}
%{if var.ingress.traefik.additional_ports != ""~}
%{for option in var.ingress.traefik.additional_ports~}
  ${option.name}:
    port: ${option.port}
    expose: true
    exposedPort: ${option.exposedPort}
    protocol: TCP
%{if !local.using_klipper_lb~}
    proxyProtocol:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
%{for ip in var.ingress.traefik.additional_trusted_ips~}
        - "${ip}"
%{endfor~}
    forwardedHeaders:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
%{for ip in var.ingress.traefik.additional_trusted_ips~}
        - "${ip}"
%{endfor~}
%{endif~}
%{endfor~}
%{endif~}
podDisruptionBudget:
  enabled: true
  maxUnavailable: 33%
additionalArguments:
  - "--providers.kubernetesingress.ingressendpoint.publishedservice=${local.ingress_controller_namespace}/traefik"
%{for option in var.ingress.traefik.additional_options~}
  - "${option}"
%{endfor~}
resources:
  requests:
    cpu: "100m"
    memory: "50Mi"
  limits:
    cpu: "300m"
    memory: "150Mi"
%{if var.ingress.replica_count < var.ingress.max_replica_count~}
autoscaling:
  enabled: true
  minReplicas: ${local.ingress_replica_count}
  maxReplicas: ${local.ingress_max_replica_count}
%{endif~}
  EOT
}
