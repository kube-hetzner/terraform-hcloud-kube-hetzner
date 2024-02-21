locals {
  cni = {
    install = {
      resources = {
        "calico" = ["https://raw.githubusercontent.com/projectcalico/calico/${coalesce(local.versions.calico, "v3.26.4")}/manifests/calico.yaml"]
        "cilium" = ["cilium.yaml"]
      }
      resource_patches = {
        "calico" = ["calico.yaml"]
      }
    }

    k3s_settings = {
      "flannel" = {
        disable-network-policy = var.cni.disable_network_policy
        flannel-backend        = var.cni.encrypt_traffic ? "wireguard-native" : "vxlan"
      }
      "calico" = {
        disable-network-policy = true
        flannel-backend        = "none"
      }
      "cilium" = {
        disable-network-policy = true
        flannel-backend        = "none"
      }
    }

    flannel = {
      iface = "eth1"
    }

    calico = {
      # Not to be confused with the other helm values, this is used for the calico.yaml kustomize patch
      # It also serves as a stub for a potential future use via helm values
      values = var.cni.calico.values != "" ? var.cni.calico.values : <<EOT
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: calico-node
  namespace: kube-system
  labels:
    k8s-app: calico-node
spec:
  template:
    spec:
      volumes:
        - name: flexvol-driver-host
          hostPath:
            type: DirectoryOrCreate
            path: /var/lib/kubelet/volumeplugins/nodeagent~uds
      containers:
        - name: calico-node
          env:
            - name: CALICO_IPV4POOL_CIDR
              value: "${var.network.cidr_blocks.ipv4.cluster}"
            - name: FELIX_WIREGUARDENABLED
              value: "${var.cni.encrypt_traffic}"

  EOT
    }

    cilium = {
      values = var.cni.cilium.values != "" ? var.cni.cilium.values : <<EOT
# Enable Kubernetes host-scope IPAM mode (required for K3s + Hetzner CCM)
ipam:
  mode: kubernetes
k8s:
  requireIPv4PodCIDR: true

# Replace kube-proxy with Cilium
kubeProxyReplacement: true

# Set Tunnel Mode or Native Routing Mode (supported by Hetzner CCM Route Controller)
routingMode: "${var.cni.cilium.routing_mode}"
%{if var.cni.cilium.routing_mode == "native"~}
ipv4NativeRoutingCIDR: "${coalesce(var.cni.cilium.ipv4_native_routing_cidr, var.network.cidr_blocks.ipv4.cluster)}"
%{endif~}

endpointRoutes:
  # Enable use of per endpoint routes instead of routing via the cilium_host interface.
  enabled: true

loadBalancer:
  # Enable LoadBalancer & NodePort XDP Acceleration (direct routing (routingMode=native) is recommended to achieve optimal performance)
  acceleration: native

bpf:
  # Enable eBPF-based Masquerading ("The eBPF-based implementation is the most efficient implementation")
  masquerade: true
%{if var.cni.encrypt_traffic}
encryption:
  enabled: true
  type: wireguard
%{endif~}
%{if var.cni.cilium.egress_gateway_enabled}
egressGateway:
  enabled: true
%{endif~}

MTU: 1450
  EOT
    }
  }
}
