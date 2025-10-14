apiVersion: v1
kind: Secret
metadata:
  name: hcloud
  namespace: kube-system
stringData:
%{ for secret_key, secret_value in hcloud_secrets ~}
  ${secret_key}: '${secret_value}'
%{ endfor ~}

---
apiVersion: v1
kind: Secret
metadata:
  name: hcloud-csi
  namespace: kube-system
stringData:
%{ for secret_key, secret_value in hcloud_csi_secrets ~}
  ${secret_key}: '${secret_value}'
%{ endfor ~}