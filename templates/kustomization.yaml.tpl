---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- "https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/download/${ccm_version}/ccm-networks.yaml"
- "https://raw.githubusercontent.com/hetznercloud/csi-driver/${csi_version}/deploy/kubernetes/hcloud-csi.yml"
- "https://github.com/weaveworks/kured/releases/download/${kured_version}/kured-${kured_version}-dockerhub.yaml"

patchesStrategicMerge:
- |-
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
- |-
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: hcloud-cloud-controller-manager
    namespace: kube-system
  spec:
    template:
      spec:
        containers:
          - name: hcloud-cloud-controller-manager
            command:
              - "/bin/hcloud-cloud-controller-manager"
              - "--cloud-provider=hcloud"
              - "--leader-elect=false"
              - "--allow-untagged-cloud"
              - "--allocate-node-cidrs=true"
              - "--cluster-cidr=10.42.0.0/16"
%{ if ccm_latest ~}
- |-
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: hcloud-cloud-controller-manager
    namespace: kube-system
  spec:
    template:
      spec:
        containers:
          - name: hcloud-cloud-controller-manager
            command:
              - "/bin/hcloud-cloud-controller-manager"
              - "--cloud-provider=hcloud"
              - "--leader-elect=false"
              - "--allow-untagged-cloud"
              - "--allocate-node-cidrs=true"
              - "--cluster-cidr=10.42.0.0/16"
            image: hetznercloud/hcloud-cloud-controller-manager:latest
            imagePullPolicy: Always
%{ endif ~}
%{ if csi_latest ~}
- |-
  kind: StatefulSet
  apiVersion: apps/v1
  metadata:
    name: hcloud-csi-controller
    namespace: kube-system
  spec:
    template:
      metadata:
        labels:
          app: hcloud-csi-controller
      spec:
        containers:
          - name: csi-attacher
            image: quay.io/k8scsi/csi-attacher:canary
            imagePullPolicy: Always
          - name: csi-resizer
            image: quay.io/k8scsi/csi-resizer:canary
            imagePullPolicy: Always
          - name: csi-provisioner
            image: quay.io/k8scsi/csi-provisioner:canary
            imagePullPolicy: Always
          - name: hcloud-csi-driver
            image: hetznercloud/hcloud-csi-driver:latest
            imagePullPolicy: Always
          - name: liveness-probe
            image: quay.io/k8scsi/livenessprobe:canary
            imagePullPolicy: Always
        volumes:
          - name: socket-dir
            emptyDir: {}
  ---
  kind: DaemonSet
  apiVersion: apps/v1
  metadata:
    name: hcloud-csi-node
    namespace: kube-system
    labels:
      app: hcloud-csi
  spec:
    selector:
      matchLabels:
        app: hcloud-csi
    template:
      spec:
        containers:
          - name: csi-node-driver-registrar
            image: quay.io/k8scsi/csi-node-driver-registrar:canary
            imagePullPolicy: Always
          - name: hcloud-csi-driver
            image: hetznercloud/hcloud-csi-driver:latest
            imagePullPolicy: Always
          - name: liveness-probe
            image: quay.io/k8scsi/livenessprobe:canary
            imagePullPolicy: Always
%{ endif ~}
