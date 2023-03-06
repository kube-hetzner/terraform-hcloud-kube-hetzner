variable "hcloud_token" {
  description = "Hetzner Cloud API Token."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_port" {
  description = "The main SSH port to connect to the nodes."
  type        = number
  default     = 22

  validation {
    condition     = var.ssh_port >= 0 && var.ssh_port <= 65535
    error_message = "The SSH port must use a valid range from 0 to 65535."
  }
}

variable "ssh_public_key" {
  description = "SSH public Key."
  type        = string
}

variable "ssh_private_key" {
  description = "SSH private Key."
  type        = string
  sensitive   = true
}

variable "ssh_hcloud_key_label" {
  description = "Additional SSH public Keys by hcloud label. e.g. role=admin"
  type        = string
  default     = ""
}

variable "ssh_additional_public_keys" {
  description = "Additional SSH public Keys. Use them to grant other team members root access to your cluster nodes."
  type        = list(string)
  default     = []
}

variable "hcloud_ssh_key_id" {
  description = "If passed, a key already registered within hetzner is used. Otherwise, a new one will be created by the module."
  type        = string
  default     = null
}

variable "network_region" {
  description = "Default region for network."
  type        = string
  default     = "eu-central"
}

variable "network_ipv4_cidr" {
  description = "The main network cidr that all subnets will be created upon."
  type        = string
  default     = "10.0.0.0/8"
}

variable "cluster_ipv4_cidr" {
  description = "Internal Pod CIDR, used for the controller and currently for calico."
  type        = string
  default     = "10.42.0.0/16"
}

variable "load_balancer_location" {
  description = "Default load balancer location."
  type        = string
  default     = "fsn1"
}

variable "load_balancer_type" {
  description = "Default load balancer server type."
  type        = string
  default     = "lb11"
}

variable "load_balancer_disable_ipv6" {
  description = "Disable ipv6 for the load balancer."
  type        = bool
  default     = false
}

variable "control_plane_nodepools" {
  description = "Number of control plane nodes."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    backups     = optional(bool)
    labels      = list(string)
    taints      = list(string)
    count       = number
  }))
  default = []
}

variable "agent_nodepools" {
  description = "Number of agent nodes."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    backups     = optional(bool)
    floating_ip = optional(bool)
    labels      = list(string)
    taints      = list(string)
    count       = number
  }))
  default = []
}

variable "cluster_autoscaler_image" {
  type        = string
  default     = "k8s.gcr.io/autoscaling/cluster-autoscaler"
  description = "Image of Kubernetes Cluster Autoscaler for Hetzner Cloud to be used."
}

variable "cluster_autoscaler_version" {
  type        = string
  default     = "v1.25.0"
  description = "Version of Kubernetes Cluster Autoscaler for Hetzner Cloud. Should be aligned with Kubernetes version"
}

variable "autoscaler_nodepools" {
  description = "Cluster autoscaler nodepools."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    min_nodes   = number
    max_nodes   = number
  }))
  default = []
}

variable "hetzner_ccm_version" {
  type        = string
  default     = null
  description = "Version of Kubernetes Cloud Controller Manager for Hetzner Cloud."
}

variable "hetzner_csi_version" {
  type        = string
  default     = null
  description = "Version of Container Storage Interface driver for Hetzner Cloud."
}

variable "restrict_outbound_traffic" {
  type        = bool
  default     = true
  description = "Whether or not to restrict the outbound traffic."
}

variable "enable_klipper_metal_lb" {
  type        = bool
  default     = false
  description = "Use klipper load balancer."
}

variable "etcd_s3_backup" {
  description = "Etcd cluster state backup to S3 storage"
  type        = map(any)
  sensitive   = true
  default     = {}
}

variable "ingress_controller" {
  type        = string
  default     = "traefik"
  description = "The name of the ingress controller."

  validation {
    condition     = contains(["traefik", "nginx", "none"], var.ingress_controller)
    error_message = "Must be one of \"traefik\" or \"nginx\" or \"none\""
  }
}

variable "ingress_replica_count" {
  type        = number
  default     = 0
  description = "Number of replicas per ingress controller. 0 means autodetect based on the number of agent nodes."

  validation {
    condition     = var.ingress_replica_count >= 0
    error_message = "Number of ingress replicas can't be below 0."
  }
}

variable "traefik_redirect_to_https" {
  type        = bool
  default     = true
  description = "Should traefik redirect http traffic to https."
}

variable "traefik_additional_options" {
  type        = list(string)
  default     = []
  description = "Additional options to pass to Traefik as a list of strings. These are the ones that go into the additionalArguments section of the Traefik helm values file."
}

variable "traefik_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Traefik as 'valuesContent' at the HelmChart."
}

variable "nginx_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to nginx as 'valuesContent' at the HelmChart."
}

variable "allow_scheduling_on_control_plane" {
  type        = bool
  default     = false
  description = "Whether to allow non-control-plane workloads to run on the control-plane nodes."
}

variable "enable_metrics_server" {
  type        = bool
  default     = true
  description = "Whether to enable or disbale k3s mertric server."
}

variable "initial_k3s_channel" {
  type        = string
  default     = "v1.25"
  description = "Allows you to specify an initial k3s channel."

  validation {
    condition     = contains(["stable", "latest", "testing", "v1.16", "v1.17", "v1.18", "v1.19", "v1.20", "v1.21", "v1.22", "v1.23", "v1.24", "v1.25", "v1.26"], var.initial_k3s_channel)
    error_message = "The initial k3s channel must be one of stable, latest or testing, or any of the minor kube versions like v1.22."
  }
}

variable "automatically_upgrade_k3s" {
  type        = bool
  default     = true
  description = "Whether to automatically upgrade k3s based on the selected channel."
}

variable "automatically_upgrade_os" {
  type        = bool
  default     = true
  description = "Whether to enable or disable automatic os updates. Defaults to true. Should be disabled for single-node clusters"
}

variable "extra_firewall_rules" {
  type        = list(any)
  default     = []
  description = "Additional firewall rules to apply to the cluster."
}

variable "use_cluster_name_in_node_name" {
  type        = bool
  default     = true
  description = "Whether to use the cluster name in the node name."
}

variable "cluster_name" {
  type        = string
  default     = "k3s"
  description = "Name of the cluster."

  validation {
    condition     = can(regex("^[a-z0-9\\-]+$", var.cluster_name))
    error_message = "The cluster name must be in the form of lowercase alphanumeric characters and/or dashes."
  }
}

variable "base_domain" {
  type        = string
  default     = ""
  description = "Base domain of the cluster, used for reserve dns."

  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.base_domain)) || var.base_domain == ""
    error_message = "It must be a valid domain name (FQDN)."
  }
}

variable "placement_group_disable" {
  type        = bool
  default     = false
  description = "Whether to disable placement groups."
}

variable "disable_network_policy" {
  type        = bool
  default     = false
  description = "Disable k3s default network policy controller (default false, automatically true for calico and cilium)."
}

variable "cni_plugin" {
  type        = string
  default     = "flannel"
  description = "CNI plugin for k3s."

  validation {
    condition     = contains(["flannel", "calico", "cilium"], var.cni_plugin)
    error_message = "The cni_plugin must be one of \"flannel\", \"calico\", or \"cilium\"."
  }
}

variable "cilium_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Cilium as 'valuesContent' at the HelmChart."
}

variable "calico_values" {
  type        = string
  default     = ""
  description = "Just a stub for a future helm implementation. Now it can be used to replace the calico kustomize patch of the calico manifest."
}

variable "enable_longhorn" {
  type        = bool
  default     = false
  description = "Whether or not to enable Longhorn."
}
variable "longhorn_repository" {
  type        = string
  default     = "https://charts.longhorn.io"
  description = "By default the official chart which may be incompatible with rancher is used. If you need to fully support rancher switch to https://charts.rancher.io."
}
variable "longhorn_namespace" {
  type        = string
  default     = "longhorn-system"
  description = "Namespace for longhorn deployment, defaults to 'longhorn-system'"
}
variable "longhorn_fstype" {
  type        = string
  default     = "ext4"
  description = "The longhorn fstype."

  validation {
    condition     = contains(["ext4", "xfs"], var.longhorn_fstype)
    error_message = "Must be one of \"ext4\" or \"xfs\""
  }
}

variable "longhorn_replica_count" {
  type        = number
  default     = 3
  description = "Number of replicas per longhorn volume."

  validation {
    condition     = var.longhorn_replica_count > 0
    error_message = "Number of longhorn replicas can't be below 1."
  }
}

variable "longhorn_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to longhorn as 'valuesContent' at the HelmChart."
}

variable "disable_hetzner_csi" {
  type        = bool
  default     = false
  description = "Disable hetzner csi driver."
}

variable "enable_cert_manager" {
  type        = bool
  default     = true
  description = "Enable cert manager."
}

variable "cert_manager_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Cert-Manager as 'valuesContent' at the HelmChart."
}

variable "enable_rancher" {
  type        = bool
  default     = false
  description = "Enable rancher."
}

variable "rancher_install_channel" {
  type        = string
  default     = "stable"
  description = "The rancher installation channel."

  validation {
    condition     = contains(["stable", "latest"], var.rancher_install_channel)
    error_message = "The allowed values for the Rancher install channel are stable or latest."
  }
}

variable "rancher_hostname" {
  type        = string
  default     = ""
  description = "The rancher hostname."

  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.rancher_hostname)) || var.rancher_hostname == ""
    error_message = "It must be a valid domain name (FQDN)."
  }
}

variable "lb_hostname" {
  type        = string
  default     = ""
  description = "The Hetzner Load Balancer hostname, for either Traefik or Ingress-Nginx."

  validation {
    condition     = can(regex("^(?:(?:(?:[A-Za-z0-9])|(?:[A-Za-z0-9](?:[A-Za-z0-9\\-]+)?[A-Za-z0-9]))+(\\.))+([A-Za-z]{2,})([\\/?])?([\\/?][A-Za-z0-9\\-%._~:\\/?#\\[\\]@!\\$&\\'\\(\\)\\*\\+,;=]+)?$", var.lb_hostname)) || var.lb_hostname == ""
    error_message = "It must be a valid domain name (FQDN)."
  }
}

variable "rancher_registration_manifest_url" {
  type        = string
  description = "The url of a rancher registration manifest to apply. (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/)."
  default     = ""
  sensitive   = true
}

variable "rancher_bootstrap_password" {
  type        = string
  default     = ""
  description = "Rancher bootstrap password."
  sensitive   = true

  validation {
    condition     = (length(var.rancher_bootstrap_password) >= 48) || (length(var.rancher_bootstrap_password) == 0)
    error_message = "The Rancher bootstrap password must be at least 48 characters long."
  }
}

variable "rancher_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Rancher as 'valuesContent' at the HelmChart."
}

variable "kured_version" {
  type        = string
  default     = null
  description = "Version of Kured."
}

variable "kured_options" {
  type    = map(string)
  default = {}
}

variable "block_icmp_ping_in" {
  type        = bool
  default     = false
  description = "Block entering ICMP ping."
}

variable "use_control_plane_lb" {
  type        = bool
  default     = false
  description = "When this is enabled, rather than the first node, all external traffic will be routed via a control-plane loadbalancer, allowing for high availability."
}

variable "dns_servers" {
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1"]
  description = "IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner."
}

variable "additional_k3s_environment" {
  type        = map(any)
  default     = {}
  description = "Additional environment variables for the k3s binary. See for example https://docs.k3s.io/advanced#configuring-an-http-proxy ."
}

variable "preinstall_exec" {
  type        = list(string)
  default     = []
  description = "Additional to execute before the install calls, for example fetching and installing certs."
}


variable "extra_packages_to_install" {
  type        = list(string)
  default     = []
  description = "A list of additional packages to install on nodes."
}

variable "extra_kustomize_parameters" {
  type        = map(any)
  default     = {}
  description = "All values will be passed to the `kustomization.tmp.yml` template."
}

variable "create_kubeconfig" {
  type        = bool
  default     = true
  description = "Create the kubeconfig as a local file resource. Should be disabled for automatic runs."
}

variable "create_kustomization" {
  type        = bool
  default     = true
  description = "Create the kustomization backup as a local file resource. Should be disabled for automatic runs."
}

variable "enable_wireguard" {
  type        = bool
  default     = false
  description = "Use wireguard-native as the backend for CNI."
}

variable "control_planes_custom_config" {
  type        = map(any)
  default     = {}
  description = "Custom control plane configuration e.g to allow etcd monitoring."
}

variable "k3s_registries" {
  description = "K3S registries.yml contents. It used to access private docker registries."
  default     = " "
  type        = string
}

variable "opensuse_microos_mirror_link" {
  description = "The mirror link to use for the opensuse microos image."
  default     = "https://mirror.dogado.de/opensuse/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2"
  type        = string

  validation {
    condition     = can(regex("^https.*openSUSE-MicroOS\\.x86_64[\\-0-9\\.]*-OpenStack-Cloud.*\\.qcow2$", var.opensuse_microos_mirror_link))
    error_message = "You need to use a mirror link from https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2.mirrorlist"
  }
}

variable "additional_tls_sans" {
  description = "Additional TLS SANs to allow connection to control-plane through it."
  default     = []
  type        = list(string)
}

variable "calico_version" {
  type        = string
  default     = null
  description = "Version of Calico."
}
