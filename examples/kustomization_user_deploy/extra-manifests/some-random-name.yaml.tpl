apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  selector:
    app: nginx
  ports:

- name: web
    port: 80
    targetPort: 80

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  ## In case you have an non default cert-manager...
  #annotations:
  #  cert-manager.io/cluster-issuer: letsencrypt-prod
  name: frontend
spec:
  rules:
    - host: <SOME.Domain.TLD>
      http:
        paths:
          - path: /
            pathType: Exact
            backend:
              service:
                name: frontend
                port:
                  name: web
#  tls:
#    - hosts:
#        - <SOME.Domain.TLD>
#      secretName: <SOME.Domain.TLD>
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.15.4
        ports:
        - containerPort: 80