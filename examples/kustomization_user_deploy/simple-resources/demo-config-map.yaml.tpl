apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-config
data:
  someConfigKey: ${sealed_secrets_crt}
