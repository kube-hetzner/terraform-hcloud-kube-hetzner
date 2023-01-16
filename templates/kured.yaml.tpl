apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kured
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: kured
  template:
    metadata:
      labels:
        name: kured
    spec:
      serviceAccountName: kured
      containers:
        - name: kured
          command:
            - /usr/bin/kured
            - --reboot-command=/usr/bin/systemctl reboot
            - --pre-reboot-node-labels=kured=rebooting
            - --post-reboot-node-labels=kured=done
            - --period=5m
            %{~ for key, value in options ~}
            - --${key}=${value}
            %{~ endfor ~}

