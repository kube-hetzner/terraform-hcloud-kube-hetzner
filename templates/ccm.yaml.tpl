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
            - "--cluster-cidr=${cluster_cidr_ipv4}"
%{ if allow_scheduling_on_control_plane ~}
            - "--feature-gates=LegacyNodeRoleBehavior=false" 
%{ endif ~}
          env:
            - name: "HCLOUD_LOAD_BALANCERS_LOCATION"
              value: "${default_lb_location}"
            - name: "HCLOUD_LOAD_BALANCERS_USE_PRIVATE_IP"
              value: "true"
            - name: "HCLOUD_LOAD_BALANCERS_ENABLED"
              value: "${using_hetzner_lb}"
