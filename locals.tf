locals {
  # if we are in a single cluster config, we use the default klipper lb instead of Hetzner LB
  is_single_node_cluster = var.control_plane_count + sum(concat([for v in var.agent_nodepools : v.count], [0])) == 1
  ssh_public_key         = trimspace(file(var.public_key))
  # ssh_private_key is either the contents of var.private_key or null to use a ssh agent.
  ssh_private_key = var.private_key == null ? null : trimspace(file(var.private_key))
  # ssh_identity is not set if the private key is passed directly, but if ssh agent is used, the public key tells ssh agent which private key to use.
  # For terraforms provisioner.connection.agent_identity, we need the public key as a string.
  ssh_identity = var.private_key == null ? local.ssh_public_key : null
  # ssh_identity_file is used for ssh "-i" flag, its the private key if that is set, or a public key file
  # if an ssh agent is used.
  ssh_identity_file = var.private_key == null ? var.public_key : var.private_key
  # shared flags for ssh to ignore host keys, to use root and our ssh identity file for all connections during provisioning.
  ssh_args = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${local.ssh_identity_file}"

  ccm_version   = var.hetzner_ccm_version != null ? var.hetzner_ccm_version : data.github_release.hetzner_ccm.release_tag
  csi_version   = var.hetzner_csi_version != null ? var.hetzner_csi_version : data.github_release.hetzner_csi.release_tag
  kured_version = data.github_release.kured.release_tag

  # The following IPs are important to be whitelisted because they communicate with Hetzner services and enable the CCM and CSI to work properly.
  # Source https://github.com/hetznercloud/csi-driver/issues/204#issuecomment-848625566
  hetzner_metadata_service_ipv4 = "169.254.169.254/32"
  hetzner_cloud_api_ipv4        = "213.239.246.1/32"

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

    # Allow all traffic to the ssh port
    {
      direction = "in"
      protocol  = "tcp"
      port      = "22"
      source_ips = [
        "0.0.0.0/0"
      ]
    },

    # Allow ping on ipv4
    {
      direction = "in"
      protocol  = "icmp"
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
    ], !local.is_single_node_cluster ? [] : [
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
  ])

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

  install_k3s_server = concat(local.common_commands_install_k3s, ["curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_SELINUX_RPM=true INSTALL_K3S_CHANNEL=${var.initial_k3s_channel} INSTALL_K3S_EXEC=server sh -"], local.apply_k3s_selinux)
  install_k3s_agent  = concat(local.common_commands_install_k3s, ["curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_SELINUX_RPM=true INSTALL_K3S_CHANNEL=${var.initial_k3s_channel} INSTALL_K3S_EXEC=agent sh -"], local.apply_k3s_selinux)

  agent_nodepools = merge([
    for nodepool_obj in var.agent_nodepools : {
      for index in range(nodepool_obj.count) :
      format("%s-%s", nodepool_obj.name, index) => {
        nodepool_name : nodepool_obj.name,
        server_type : nodepool_obj.server_type,
        index : index
      }
    }
  ]...)

  # The main network cidr that all subnets will be created upon
  network_ipv4_cidr = "10.0.0.0/8"

  # The first two subnets are respectively the default subnet 10.0.0.0/16 use for potientially anything and 10.1.0.0/16 used for control plane nodes.
  # the rest of the subnets are for agent nodes in each nodepools.
  network_ipv4_subnets = [for index in range(length(var.agent_nodepools) + 2) : cidrsubnet(local.network_ipv4_cidr, 8, index)]
}
