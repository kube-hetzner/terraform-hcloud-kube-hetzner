locals {
  # ssh_agent_identity is not set if the private key is passed directly, but if ssh agent is used, the public key tells ssh agent which private key to use.
  # For terraforms provisioner.connection.agent_identity, we need the public key as a string.
  ssh_agent_identity = var.ssh_private_key == null ? var.ssh_public_key : null

  # If passed, a key already registered within hetzner is used. 
  # Otherwise, a new one will be created by the module.
  hcloud_ssh_key_id = var.hcloud_ssh_key_id == null ? hcloud_ssh_key.k3s[0].id : var.hcloud_ssh_key_id

  ccm_version   = var.hetzner_ccm_version != null ? var.hetzner_ccm_version : data.github_release.hetzner_ccm.release_tag
  csi_version   = var.hetzner_csi_version != null ? var.hetzner_csi_version : data.github_release.hetzner_csi.release_tag
  kured_version = var.kured_version != null ? var.kured_version : data.github_release.kured.release_tag

  common_commands_install_k3s = [
    "set -ex",
    # prepare the k3s config directory
    "mkdir -p /etc/rancher/k3s",
    # move the config file into place
    "mv /tmp/config.yaml /etc/rancher/k3s/config.yaml",
    # if the server has already been initialized just stop here
    "[ -e /etc/rancher/k3s/k3s.yaml ] && exit 0",
  ]

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
        index : node_index
      }
    }
  ]...)

  # The main network cidr that all subnets will be created upon
  network_ipv4_cidr = "10.0.0.0/8"

  # The first two subnets are respectively the default subnet 10.0.0.0/16 use for potientially anything and 10.1.0.0/16 used for control plane nodes.
  # the rest of the subnets are for agent nodes in each nodepools.
  network_ipv4_subnets = [for index in range(256) : cidrsubnet(local.network_ipv4_cidr, 8, index)]

  # if we are in a single cluster config, we use the default klipper lb instead of Hetzner LB
  control_plane_count    = sum([for v in var.control_plane_nodepools : v.count])
  agent_count            = sum([for v in var.agent_nodepools : v.count])
  is_single_node_cluster = (local.control_plane_count + local.agent_count) == 1

  using_klipper_lb = var.enable_klipper_metal_lb || local.is_single_node_cluster

  has_external_load_balancer = local.using_klipper_lb || local.ingress_controller == "none"

  # disable k3s extras
  disable_extras = concat(["local-storage"], local.using_klipper_lb ? [] : ["servicelb"], var.enable_traefik ? [] : [
    "traefik"
  ], var.enable_metrics_server ? [] : ["metrics-server"])

  # Default k3s node labels
  default_agent_labels         = concat([], var.automatically_upgrade_k3s ? ["k3s_upgrade=true"] : [])
  default_control_plane_labels = concat([], var.automatically_upgrade_k3s ? ["k3s_upgrade=true"] : [])

  allow_scheduling_on_control_plane = local.is_single_node_cluster ? true : var.allow_scheduling_on_control_plane

  # Default k3s node taints
  default_control_plane_taints = concat([], local.allow_scheduling_on_control_plane ? [] : ["node-role.kubernetes.io/control-plane:NoSchedule"])
  default_agent_taints         = concat([], var.cni_plugin == "cilium" ? ["node.cilium.io/agent-not-ready:NoExecute"] : [])


  packages_to_install = concat(var.enable_longhorn ? ["open-iscsi", "nfs-client", "xfsprogs"] : [], var.extra_packages_to_install)

  # The following IPs are important to be whitelisted because they communicate with Hetzner services and enable the CCM and CSI to work properly.
  # Source https://github.com/hetznercloud/csi-driver/issues/204#issuecomment-848625566
  hetzner_metadata_service_ipv4 = "169.254.169.254/32"
  hetzner_cloud_api_ipv4        = "213.239.246.1/32"

  # internal Pod CIDR, used for the controller and currently for calico
  cluster_cidr_ipv4 = "10.42.0.0/16"

  whitelisted_ips = [
    local.network_ipv4_cidr,
    local.hetzner_metadata_service_ipv4,
    local.hetzner_cloud_api_ipv4,
    "127.0.0.1/32",
  ]

  base_firewall_rules = concat([
    # Allowing internal cluster traffic and Hetzner metadata service and cloud API IPs
    {
      direction  = "in"
      protocol   = "tcp"
      port       = "any"
      source_ips = local.whitelisted_ips
    },
    {
      direction  = "in"
      protocol   = "udp"
      port       = "any"
      source_ips = local.whitelisted_ips
    },
    {
      direction  = "in"
      protocol   = "icmp"
      source_ips = local.whitelisted_ips
    },

    # Allow all traffic to the kube api server
    {
      direction = "in"
      protocol  = "tcp"
      port      = "6443"
      source_ips = [
        "0.0.0.0/0"
      ]
    },

    # Allow all traffic to the ssh ports
    {
      direction = "in"
      protocol  = "tcp"
      port      = "22"
      source_ips = [
        "0.0.0.0/0"
      ]
    },
    {
      direction = "in"
      protocol  = "tcp"
      port      = var.ssh_port
      source_ips = [
        "0.0.0.0/0"
      ]
    },

    # Allow basic out traffic
    # ICMP to ping outside services
    {
      direction = "out"
      protocol  = "icmp"
      destination_ips = [
        "0.0.0.0/0"
      ]
    },

    # DNS
    {
      direction = "out"
      protocol  = "tcp"
      port      = "53"
      destination_ips = [
        "0.0.0.0/0"
      ]
    },
    {
      direction = "out"
      protocol  = "udp"
      port      = "53"
      destination_ips = [
        "0.0.0.0/0"
      ]
    },

    # HTTP(s)
    {
      direction = "out"
      protocol  = "tcp"
      port      = "80"
      destination_ips = [
        "0.0.0.0/0"
      ]
    },
    {
      direction = "out"
      protocol  = "tcp"
      port      = "443"
      destination_ips = [
        "0.0.0.0/0"
      ]
    },

    #NTP
    {
      direction = "out"
      protocol  = "udp"
      port      = "123"
      destination_ips = [
        "0.0.0.0/0"
      ]
    }
    ], !local.using_klipper_lb ? [] : [
    # Allow incoming web traffic for single node clusters, because we are using k3s servicelb there,
    # not an external load-balancer.
    {
      direction = "in"
      protocol  = "tcp"
      port      = "80"
      source_ips = [
        "0.0.0.0/0"
      ]
    },
    {
      direction = "in"
      protocol  = "tcp"
      port      = "443"
      source_ips = [
        "0.0.0.0/0"
      ]
    }
    ], var.block_icmp_ping_in ? [] : [
    {
      direction = "in"
      protocol  = "icmp"
      source_ips = [
        "0.0.0.0/0"
      ]
    }
    ], var.cni_plugin != "cilium" ? [] : [
    {
      direction = "in"
      protocol  = "tcp"
      port      = "4244-4245"
      source_ips = [
        "0.0.0.0/0"
      ]
    }
  ])

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
    "calico" = ["https://projectcalico.docs.tigera.io/manifests/calico.yaml"]
    "cilium" = ["cilium.yaml"]
  }

  cni_install_resource_patches = {
    "calico" = ["calico.yaml"]
  }

  cni_k3s_settings = {
    "flannel" = {
      disable-network-policy = var.disable_network_policy
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

  ingress_controller = var.enable_traefik ? "traefik" : var.enable_nginx ? "nginx" : "none"
  ingress_controller_service_names = {
    "traefik" = "traefik"
    "nginx"   = "ngx-ingress-nginx-controller"
  }

  ingress_controller_install_resources = {
    "traefik" = ["traefik_config.yaml"]
    "nginx"   = ["nginx_ingress.yaml"]
  }

  cilium_values = var.cilium_values != "" ? var.cilium_values : <<EOT
ipam:
 operator:
  clusterPoolIPv4PodCIDRList:
   - ${local.cluster_cidr_ipv4}
devices: "eth1"
  EOT

  longhorn_values = var.longhorn_values != "" ? var.longhorn_values : <<EOT
defaultSettings:
  defaultDataPath: /var/longhorn
persistence:
  defaultFsType: ${var.longhorn_fstype}
  defaultClassReplicaCount: ${var.longhorn_replica_count}
  %{if var.disable_hetzner_csi~}defaultClass: true%{else~}defaultClass: false%{endif~}
  EOT

  nginx_ingress_values = var.nginx_ingress_values != "" ? var.nginx_ingress_values : <<EOT
controller:
  watchIngressWithoutClass: "true"
  kind: "Deployment"
  replicaCount: ${(local.agent_count > 2) ? 3 : (local.agent_count == 2) ? 2 : 1}
  config:
    "use-forwarded-headers": "true"
    "compute-full-forwarded-for": "true"
    "use-proxy-protocol": "true"
  service:
    annotations:
      "load-balancer.hetzner.cloud/name": "${var.cluster_name}"
      "load-balancer.hetzner.cloud/use-private-ip": "true"
      "load-balancer.hetzner.cloud/disable-private-ingress": "true"
      "load-balancer.hetzner.cloud/ipv6-disabled": "${var.load_balancer_disable_ipv6}"
      "load-balancer.hetzner.cloud/location": "${var.load_balancer_location}"
      "load-balancer.hetzner.cloud/type": "${var.load_balancer_type}"
      "load-balancer.hetzner.cloud/uses-proxyprotocol": "true"
  EOT

  traefik_ingress_values = var.traefik_ingress_values != "" ? var.traefik_ingress_values : <<EOT
globalArguments: []
service:
  enabled: true
  type: LoadBalancer
  %{if !local.using_klipper_lb}
  annotations:
    "load-balancer.hetzner.cloud/name": "${var.cluster_name}"
    "load-balancer.hetzner.cloud/use-private-ip": "true"
    "load-balancer.hetzner.cloud/disable-private-ingress": "true"
    "load-balancer.hetzner.cloud/ipv6-disabled": "${var.load_balancer_disable_ipv6}"
    "load-balancer.hetzner.cloud/location": "${var.load_balancer_location}"
    "load-balancer.hetzner.cloud/type": "${var.load_balancer_type}"
    "load-balancer.hetzner.cloud/uses-proxyprotocol": "true"
  %{endif}
additionalArguments:
%{if !local.using_klipper_lb}
- "--entryPoints.web.proxyProtocol.trustedIPs=127.0.0.1/32,10.0.0.0/8"
- "--entryPoints.websecure.proxyProtocol.trustedIPs=127.0.0.1/32,10.0.0.0/8"
- "--entryPoints.web.forwardedHeaders.trustedIPs=127.0.0.1/32,10.0.0.0/8"
- "--entryPoints.websecure.forwardedHeaders.trustedIPs=127.0.0.1/32,10.0.0.0/8"
%{endif}
%{for option in var.traefik_additional_options~}
- "${option}"
%{endfor~}
%{if var.traefik_acme_tls}
- "--certificatesresolvers.le.acme.tlschallenge=true"
- "--certificatesresolvers.le.acme.email=${var.traefik_acme_email}"
- "--certificatesresolvers.le.acme.storage=/data/acme.json"
%{endif}
  EOT

  rancher_values = var.rancher_values != "" ? var.rancher_values : <<EOT
hostname: "${var.rancher_hostname}"
replicas: ${length(local.control_plane_nodes)}
bootstrapPassword: "${length(var.rancher_bootstrap_password) == 0 ? resource.random_password.rancher_bootstrap[0].result : var.rancher_bootstrap_password}"
  EOT

  cert_manager_values = var.cert_manager_values != "" ? var.cert_manager_values : <<EOT
installCRDs: true
  EOT
}
