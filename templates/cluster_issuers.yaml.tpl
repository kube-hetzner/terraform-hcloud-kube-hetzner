
%{if hetzner_dns_api_key != ""~}
apiVersion: v1
kind: Secret
metadata:
  name: hetzner-dns-secret
  namespace: cert-manager
type: Opaque
data:
  api-key: ${hetzner_dns_api_key}
---
%{endif~}
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cert-manager-webhook-hetzner
  namespace: cert-manager
spec:
  chart: cert-manager-webhook-hetzner
  version: 1.3.1
  repo: https://vadimkim.github.io/cert-manager-webhook-hetzner
  valuesContent: |-
    groupName: "${cluster_name}.${common_name}"
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
  namespace: cert-manager
spec:
  acme:
    email: ${cert_manager_email}
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          ingressClassName: ${ingress_controller}
    - dns01:
        webhook:
          groupName: "${cluster_name}.${common_name}"
          solverName: hetzner
          config:
            secretName: hetzner-dns-secret
            zoneName: ${common_name}
            apiUrl: https://dns.hetzner.com/api/v1
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    email: ${cert_manager_email}
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          ingressClassName: ${ingress_controller}
    - dns01:
        webhook:
          groupName: "${cluster_name}.${common_name}"
          solverName: hetzner
          config:
            secretName: hetzner-dns-secret
            zoneName: ${common_name}
            apiUrl: https://dns.hetzner.com/api/v1
