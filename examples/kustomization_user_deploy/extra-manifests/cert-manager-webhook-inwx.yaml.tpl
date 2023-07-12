---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cert-manager-webhook-inwx
spec:
  chart: cert-manager-webhook-inwx
  targetNamespace: cert-manager
  repo: https://smueller18.gitlab.io/helm-charts
---
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  valuesContent: |-
    ingressShim:
      defaultIssuerName: letsencrypt-prod
      defaultIssuerKind: ClusterIssuer
---
apiVersion: v1
kind: Secret
metadata:
  name: inwx-credentials
stringData:
  username: some@one.tld
  password: verySecret1234!!
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:

  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory

    # Email address used for ACME registration
    email: hosting@solar-log.com # REPLACE THIS WITH YOUR EMAIL!!!

    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod

    solvers:
      - dns01:
          webhook:
            groupName: cert-manager-webhook-inwx.smueller18.gitlab.com
            solverName: inwx
            config:
              ttl: 300 # default 300
              sandbox: false # default false
              usernameSecretKeyRef:
                name: inwx-credentials
                key: username
              passwordSecretKeyRef:
                name: inwx-credentials
                key: password
