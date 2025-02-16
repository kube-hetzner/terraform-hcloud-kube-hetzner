apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    email: <youremail@domain.com> <--- change this to your email
    server: https://acme-v02.api.letsencrypt.org/directory | https://acme-staging-v02.api.letsencrypt.org/directory <-- pick one
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
      - http01:
          ingress:
            ingressClassName: traefik
