locals {
  # ssh_agent_identity is not set if the private key is passed directly, but if ssh agent is used, the public key tells ssh agent which private key to use.
  # For terraforms provisioner.connection.agent_identity, we need the public key as a string.
  ssh_agent_identity = var.ssh_private_key == null ? var.ssh_public_key : null

  # If passed, a key already registered within hetzner is used.
  # Otherwise, a new one will be created by the module.
  hcloud_ssh_key_id = var.hcloud_ssh_key_id == null ? hcloud_ssh_key.k3s[0].id : var.hcloud_ssh_key_id

  ccm_version    = var.hetzner_ccm_version != null ? var.hetzner_ccm_version : data.github_release.hetzner_ccm[0].release_tag
  csi_version    = var.hetzner_csi_version != null ? var.hetzner_csi_version : data.github_release.hetzner_csi[0].release_tag
  kured_version  = var.kured_version != null ? var.kured_version : data.github_release.kured[0].release_tag
  calico_version = var.calico_version != null ? var.calico_version : data.github_release.calico[0].release_tag

  additional_k3s_environment = join("\n",
    [
      for var_name, var_value in var.additional_k3s_environment :
      "${var_name}=\"${var_value}\""
    ]
  )
  install_additional_k3s_environment = <<-EOT
  cat >> /etc/environment <<EOF
  ${local.additional_k3s_environment}
  EOF
  set -a; source /etc/environment; set +a;
  EOT

  common_commands_install_k3s = concat(
    [
      "set -ex",
      # prepare the k3s config directory
      "mkdir -p /etc/rancher/k3s",
      # move the config file into place and adjust permissions
      "mv /tmp/config.yaml /etc/rancher/k3s/config.yaml",
      "chmod 0600 /etc/rancher/k3s/config.yaml",
      # if the server has already been initialized just stop here
      "[ -e /etc/rancher/k3s/k3s.yaml ] && exit 0",
      local.install_additional_k3s_environment,
    ],
    # User-defined commands to execute just before installing k3s.
    var.preinstall_exec,
  )


  apply_k3s_selinux = ["/sbin/semodule -v -i /usr/share/selinux/packages/k3s.pp"]

  install_k3s_server = concat(local.common_commands_install_k3s, [
    "curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_SELINUX_RPM=true INSTALL_K3S_CHANNEL=${var.initial_k3s_channel} INSTALL_K3S_EXEC=server sh -"
  ], local.apply_k3s_selinux)
  install_k3s_agent = concat(local.common_commands_install_k3s, [
    "curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_SELINUX_RPM=true INSTALL_K3S_CHANNEL=${var.initial_k3s_channel} INSTALL_K3S_EXEC=agent sh -"
  ], local.apply_k3s_selinux)

  control_plane_nodes = merge([
    for pool_index, nodepool_obj in var.control_plane_nodepools : {
      for node_index in range(nodepool_obj.count) :
      format("%s-%s-%s", pool_index, node_index, nodepool_obj.name) => {
        nodepool_name : nodepool_obj.name,
        server_type : nodepool_obj.server_type,
        location : nodepool_obj.location,
        labels : concat(local.default_control_plane_labels, nodepool_obj.labels),
        taints : concat(local.default_control_plane_taints, nodepool_obj.taints),
        backups : nodepool_obj.backups,
        index : node_index
      }
    }
  ]...)

  agent_nodes = merge([
    for pool_index, nodepool_obj in var.agent_nodepools : {
      for node_index in range(nodepool_obj.count) :
      format("%s-%s-%s", pool_index, node_index, nodepool_obj.name) => {
        nodepool_name : nodepool_obj.name,
        server_type : nodepool_obj.server_type,
        longhorn_volume_size : lookup(nodepool_obj, "longhorn_volume_size", 0),
        location : nodepool_obj.location,
        labels : concat(local.default_agent_labels, nodepool_obj.labels),
        taints : concat(local.default_agent_taints, nodepool_obj.taints),
        backups : nodepool_obj.backups,
        index : node_index
      }
    }
  ]...)

  # The first two subnets are respectively the default subnet 10.0.0.0/16 use for potientially anything and 10.1.0.0/16 used for control plane nodes.
  # the rest of the subnets are for agent nodes in each nodepools.
  network_ipv4_subnets = [for index in range(256) : cidrsubnet(var.network_ipv4_cidr, 8, index)]

  # if we are in a single cluster config, we use the default klipper lb instead of Hetzner LB
  control_plane_count    = sum([for v in var.control_plane_nodepools : v.count])
  agent_count            = sum([for v in var.agent_nodepools : v.count])
  is_single_node_cluster = (local.control_plane_count + local.agent_count) == 1

  using_klipper_lb = var.enable_klipper_metal_lb || local.is_single_node_cluster

  has_external_load_balancer = local.using_klipper_lb || local.ingress_controller == "none"

  ingress_replica_count = (var.ingress_replica_count > 0) ? var.ingress_replica_count : (local.agent_count > 2) ? 3 : (local.agent_count == 2) ? 2 : 1

  # disable k3s extras
  disable_extras = concat(["local-storage"], local.using_klipper_lb ? [] : ["servicelb"], ["traefik"], var.enable_metrics_server ? [] : ["metrics-server"])

  # Default k3s node labels
  default_agent_labels         = concat([], var.automatically_upgrade_k3s ? ["k3s_upgrade=true"] : [])
  default_control_plane_labels = concat(["node.kubernetes.io/exclude-from-external-load-balancers=${local.allow_scheduling_on_control_plane ? "true" : "false"}"], var.automatically_upgrade_k3s ? ["k3s_upgrade=true"] : [])

  allow_scheduling_on_control_plane = (local.is_single_node_cluster || local.using_klipper_lb) ? true : var.allow_scheduling_on_control_plane

  # Default k3s node taints
  default_control_plane_taints = concat([], local.allow_scheduling_on_control_plane ? [] : ["node-role.kubernetes.io/control-plane:NoSchedule"])
  default_agent_taints         = concat([], var.cni_plugin == "cilium" ? ["node.cilium.io/agent-not-ready:NoExecute"] : [])

  packages_to_install = concat(
    var.enable_wireguard ? ["wireguard-tools"] : [],
    var.enable_longhorn ? ["open-iscsi", "nfs-client", "xfsprogs", "cryptsetup"] : [],
    var.extra_packages_to_install,
  )

  # The following IPs are important to be whitelisted because they communicate with Hetzner services and enable the CCM and CSI to work properly.
  # Source https://github.com/hetznercloud/csi-driver/issues/204#issuecomment-848625566
  hetzner_metadata_service_ipv4 = "169.254.169.254/32"
  hetzner_cloud_api_ipv4        = "213.239.246.1/32"

  whitelisted_ips = [
    var.network_ipv4_cidr,
    local.hetzner_metadata_service_ipv4,
    local.hetzner_cloud_api_ipv4,
    "127.0.0.1/32",
  ]

  base_firewall_rules = concat([
    # Allowing internal cluster traffic and Hetzner metadata service and cloud API IPs
    {
      description = "Allow Internal Cluster TCP Traffic"
      direction   = "in"
      protocol    = "tcp"
      port        = "any"
      source_ips  = local.whitelisted_ips
    },
    {
      description = "Allow Internal Cluster UDP Traffic"
      direction   = "in"
      protocol    = "udp"
      port        = "any"
      source_ips  = local.whitelisted_ips
    },

    # Allow all traffic to the kube api server
    {
      description = "Allow Incoming Requests to Kube API Server"
      direction   = "in"
      protocol    = "tcp"
      port        = "6443"
      source_ips  = ["0.0.0.0/0", "::/0"]
    },

    # Allow all traffic to the ssh ports
    {
      description = "Allow Incoming SSH Traffic"
      direction   = "in"
      protocol    = "tcp"
      port        = "22"
      source_ips  = ["0.0.0.0/0", "::/0"]
    }
    ], var.ssh_port == 22 ? [] : [
    {
      description = "Allow Incoming SSH Traffic"
      direction   = "in"
      protocol    = "tcp"
      port        = var.ssh_port
      source_ips  = ["0.0.0.0/0", "::/0"]
    },
    ], !var.restrict_outbound_traffic ? [] : [
    # Allow basic out traffic
    # ICMP to ping outside services
    {
      description     = "Allow Outbound ICMP Ping Requests"
      direction       = "out"
      protocol        = "icmp"
      port            = ""
      destination_ips = ["0.0.0.0/0", "::/0"]
    },

    # DNS
    {
      description     = "Allow Outbound TCP DNS Requests"
      direction       = "out"
      protocol        = "tcp"
      port            = "53"
      destination_ips = ["0.0.0.0/0", "::/0"]
    },
    {
      description     = "Allow Outbound UDP DNS Requests"
      direction       = "out"
      protocol        = "udp"
      port            = "53"
      destination_ips = ["0.0.0.0/0", "::/0"]
    },

    # HTTP(s)
    {
      description     = "Allow Outbound HTTP Requests"
      direction       = "out"
      protocol        = "tcp"
      port            = "80"
      destination_ips = ["0.0.0.0/0", "::/0"]
    },
    {
      description     = "Allow Outbound HTTPS Requests"
      direction       = "out"
      protocol        = "tcp"
      port            = "443"
      destination_ips = ["0.0.0.0/0", "::/0"]
    },

    #NTP
    {
      description     = "Allow Outbound UDP NTP Requests"
      direction       = "out"
      protocol        = "udp"
      port            = "123"
      destination_ips = ["0.0.0.0/0", "::/0"]
    }
    ], !local.using_klipper_lb ? [] : [
    # Allow incoming web traffic for single node clusters, because we are using k3s servicelb there,
    # not an external load-balancer.
    {
      description = "Allow Incoming HTTP Connections"
      direction   = "in"
      protocol    = "tcp"
      port        = "80"
      source_ips  = ["0.0.0.0/0", "::/0"]
    },
    {
      description = "Allow Incoming HTTPS Connections"
      direction   = "in"
      protocol    = "tcp"
      port        = "443"
      source_ips  = ["0.0.0.0/0", "::/0"]
    }
    ], var.block_icmp_ping_in ? [] : [
    {
      description = "Allow Incoming ICMP Ping Requests"
      direction   = "in"
      protocol    = "icmp"
      port        = ""
      source_ips  = ["0.0.0.0/0", "::/0"]
    }
    ], var.cni_plugin != "cilium" ? [] : [
    {
      description = "Allow Incoming Requests to Hubble Server & Hubble Relay (Cilium)"
      direction   = "in"
      protocol    = "tcp"
      port        = "4244-4245"
      source_ips  = ["0.0.0.0/0", "::/0"]
    }
  ])

  # create a new firewall list based on base_firewall_rules but with direction-protocol-port as key
  # this is needed to avoid duplicate rules
  firewall_rules = { for rule in local.base_firewall_rules : format("%s-%s-%s", lookup(rule, "direction", "null"), lookup(rule, "protocol", "null"), lookup(rule, "port", "null")) => rule }

  # do the same for var.extra_firewall_rules
  extra_firewall_rules = { for rule in var.extra_firewall_rules : format("%s-%s-%s", lookup(rule, "direction", "null"), lookup(rule, "protocol", "null"), lookup(rule, "port", "null")) => rule }

  # merge the two lists
  firewall_rules_merged = merge(local.firewall_rules, local.extra_firewall_rules)

  # convert the merged list back to a list
  firewall_rules_list = values(local.firewall_rules_merged)

  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
    "cluster"     = var.cluster_name
  }

  labels_control_plane_node = {
    role = "control_plane_node"
  }
  labels_control_plane_lb = {
    role = "control_plane_lb"
  }

  labels_agent_node = {
    role = "agent_node"
  }

  cni_install_resources = {
    "calico" = ["https://raw.githubusercontent.com/projectcalico/calico/${local.calico_version}/manifests/calico.yaml"]
    "cilium" = ["cilium.yaml"]
  }

  cni_install_resource_patches = {
    "calico" = ["calico.yaml"]
  }

  cni_k3s_settings = {
    "flannel" = {
      disable-network-policy = var.disable_network_policy
      flannel-backend        = var.enable_wireguard ? "wireguard-native" : "vxlan"
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

  etcd_s3_snapshots = length(keys(var.etcd_s3_backup)) > 0 ? merge(
    {
      "etcd-s3" = true
    },
  var.etcd_s3_backup) : {}

  kubelet_arg                 = ["cloud-provider=external", "volume-plugin-dir=/var/lib/kubelet/volumeplugins"]
  kube_controller_manager_arg = "flex-volume-plugin-dir=/var/lib/kubelet/volumeplugins"
  flannel_iface               = "eth1"

  ingress_controller = var.ingress_controller

  ingress_controller_service_names = {
    "traefik" = "traefik"
    "nginx"   = "nginx-ingress-nginx-controller"
  }

  ingress_controller_namespace_names = {
    "traefik" = "traefik"
    "nginx"   = "nginx"
  }

  ingress_controller_install_resources = {
    "traefik" = ["traefik_ingress.yaml"]
    "nginx"   = ["nginx_ingress.yaml"]
  }

  cilium_values = var.cilium_values != "" ? var.cilium_values : <<EOT
ipam:
 operator:
  clusterPoolIPv4PodCIDRList:
   - ${var.cluster_ipv4_cidr}
devices: "eth1"
%{if var.enable_wireguard~}
l7Proxy: false
encryption:
  enabled: true
  type: wireguard
%{endif~}
  EOT

  # Not to be confused with the other helm values, this is used for the calico.yaml kustomize patch
  # It also serves as a stub for a potential future use via helm values
  calico_values = var.calico_values != "" ? var.calico_values : <<EOT
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
              value: "${var.cluster_ipv4_cidr}"
            - name: FELIX_WIREGUARDENABLED
              value: "${var.enable_wireguard}"

  EOT

  longhorn_values = var.longhorn_values != "" ? var.longhorn_values : <<EOT
defaultSettings:
  defaultDataPath: /var/longhorn
persistence:
  defaultFsType: ${var.longhorn_fstype}
  defaultClassReplicaCount: ${var.longhorn_replica_count}
  %{if var.disable_hetzner_csi~}defaultClass: true%{else~}defaultClass: false%{endif~}
  EOT

  nginx_values = var.nginx_values != "" ? var.nginx_values : <<EOT
controller:
  watchIngressWithoutClass: "true"
  kind: "Deployment"
  replicaCount: ${local.ingress_replica_count}
  config:
    "use-forwarded-headers": "true"
    "compute-full-forwarded-for": "true"
    "use-proxy-protocol": "true"
%{if !local.using_klipper_lb~}
  service:
    annotations:
      "load-balancer.hetzner.cloud/name": "${var.cluster_name}"
      "load-balancer.hetzner.cloud/use-private-ip": "true"
      "load-balancer.hetzner.cloud/disable-private-ingress": "true"
      "load-balancer.hetzner.cloud/ipv6-disabled": "${var.load_balancer_disable_ipv6}"
      "load-balancer.hetzner.cloud/location": "${var.load_balancer_location}"
      "load-balancer.hetzner.cloud/type": "${var.load_balancer_type}"
      "load-balancer.hetzner.cloud/uses-proxyprotocol": "true"
%{if var.lb_hostname != ""~}
      "load-balancer.hetzner.cloud/hostname": "${var.lb_hostname}"
%{endif~}
%{endif~}
  EOT

  traefik_values = var.traefik_values != "" ? var.traefik_values : <<EOT
deployment:
  replicas: ${local.ingress_replica_count}
globalArguments: []
service:
  enabled: true
  type: LoadBalancer
%{if !local.using_klipper_lb~}
  annotations:
    "load-balancer.hetzner.cloud/name": "${var.cluster_name}"
    "load-balancer.hetzner.cloud/use-private-ip": "true"
    "load-balancer.hetzner.cloud/disable-private-ingress": "true"
    "load-balancer.hetzner.cloud/ipv6-disabled": "${var.load_balancer_disable_ipv6}"
    "load-balancer.hetzner.cloud/location": "${var.load_balancer_location}"
    "load-balancer.hetzner.cloud/type": "${var.load_balancer_type}"
    "load-balancer.hetzner.cloud/uses-proxyprotocol": "true"
%{if var.lb_hostname != ""~}
    "load-balancer.hetzner.cloud/hostname": "${var.lb_hostname}"
%{endif~}
%{endif~}
ports:
  web:
%{if var.traefik_redirect_to_https~}
    redirectTo: websecure
%{endif~}
%{if !local.using_klipper_lb~}
    proxyProtocol:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
    forwardedHeaders:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
  websecure:
    proxyProtocol:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
    forwardedHeaders:
      trustedIPs:
        - 127.0.0.1/32
        - 10.0.0.0/8
%{endif~}
%{if var.traefik_additional_options != ""~}
additionalArguments:
%{for option in var.traefik_additional_options~}
- "${option}"
%{endfor~}
%{endif~}
  EOT

  rancher_values = var.rancher_values != "" ? var.rancher_values : <<EOT
hostname: "${var.rancher_hostname != "" ? var.rancher_hostname : var.lb_hostname}"
replicas: ${length(local.control_plane_nodes)}
bootstrapPassword: "${length(var.rancher_bootstrap_password) == 0 ? resource.random_password.rancher_bootstrap[0].result : var.rancher_bootstrap_password}"
  EOT

  cert_manager_values = var.cert_manager_values != "" ? var.cert_manager_values : <<EOT
installCRDs: true
  EOT

  kured_options = merge({
    "reboot-command" : "/usr/bin/systemctl reboot",
    "pre-reboot-node-labels" : "kured=rebooting",
    "post-reboot-node-labels" : "kured=done",
    "period" : "5m",
  }, var.kured_options)

  k3s_registries_update_script = <<EOF
DATE=`date +%Y-%m-%d_%H-%M-%S`
if cmp -s /tmp/registries.yaml /etc/rancher/k3s/registries.yaml; then
  echo "No update required to the registries.yaml file"
else
  echo "Backing up /etc/rancher/k3s/registries.yaml to /tmp/registries_$DATE.yaml"
  cp /etc/rancher/k3s/registries.yaml /tmp/registries_$DATE.yaml
  echo "Updated registries.yaml detected, restart of k3s service required"
  cp /tmp/registries.yaml /etc/rancher/k3s/registries.yaml
  if systemctl is-active --quiet k3s; then
    systemctl restart k3s || (echo "Error: Failed to restart k3s. Restoring /etc/rancher/k3s/registries.yaml from backup" && cp /tmp/registries_$DATE.yaml /etc/rancher/k3s/registries.yaml && systemctl restart k3s)
  elif systemctl is-active --quiet k3s-agent; then
    systemctl restart k3s-agent || (echo "Error: Failed to restart k3s-agent. Restoring /etc/rancher/k3s/registries.yaml from backup" && cp /tmp/registries_$DATE.yaml /etc/rancher/k3s/registries.yaml && systemctl restart k3s-agent)
  else
    echo "No active k3s or k3s-agent service found"
  fi
  echo "k3s service or k3s-agent service restarted successfully"
fi
EOF
}
