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
            %{ if allow_scheduling_on_control_plane ~}- "--feature-gates=LegacyNodeRoleBehavior=false"%{ endif ~}
          %{if length(ccm_extra_env) > 0  }
          env:
          %{ for key,value in ccm_extra_env ~}
            - name: ${key}
              value: ${value}
          %{ endfor ~}
          %{ endif }
