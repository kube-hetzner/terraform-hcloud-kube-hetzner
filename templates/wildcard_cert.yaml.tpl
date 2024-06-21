%{if hetzner_dns_api_key != ""~}
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-domain
  namespace: cert-manager
spec:
  commonName: "*.${common_name}"
  dnsNames:
    - "*.${common_name}"
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer 
  secretName: wildcard-domain-secret
  %{if reflector_enabled}
  secretTemplate:
    annotations:
      reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
      reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: "" 
      reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true" 
      reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: ""
  %{endif}
%{endif~}
