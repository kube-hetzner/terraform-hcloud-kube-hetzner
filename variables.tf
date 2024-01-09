variable "microos_x86_snapshot_id" {
  description = "MicroOS x86 snapshot ID to be used. Per default empty, the most recent image created using createkh will be used"
  type        = string
  default     = ""
}

variable "microos_arm_snapshot_id" {
  description = "MicroOS ARM snapshot ID to be used. Per default empty, the most recent image created using createkh will be used"
  type        = string
  default     = ""
}

variable "network_region" {
  description = "Default region for network."
  type        = string
  default     = "eu-central"
}
variable "existing_network_id" {
  # Unfortunately, we need this to be a list or null. If we only use a plain
  # string here, and check that existing_network_id is null, terraform will
  # complain that it cannot set `count` variables based on existing_network_id
  # != null, because that id is an output value from
  # hcloud_network.your_network.id, which terraform will only know after its
  # construction.
  description = "If you want to create the private network before calling this module, you can do so and pass its id here. NOTE: make sure to adapt network_ipv4_cidr accordingly to a range which does not collide with your other nodes."
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = length(var.existing_network_id) == 0 || (can(var.existing_network_id[0]) && length(var.existing_network_id) == 1)
    error_message = "If you pass an existing_network_id, it must be enclosed in square brackets: [id]. This is necessary to be able to unambiguously distinguish between an empty network id (default) and a user-supplied network id."
  }
}
variable "network_ipv4_cidr" {
  description = "The main network cidr that all subnets will be created upon."
  type        = string
  default     = "10.0.0.0/8"
}

variable "cluster_ipv4_cidr" {
  description = "Internal Pod CIDR, used for the controller and currently for calico/cilium."
  type        = string
  default     = "10.42.0.0/16"
}

variable "service_ipv4_cidr" {
  description = "Internal Service CIDR, used for the controller and currently for calico/cilium."
  type        = string
  default     = "10.43.0.0/16"
}

variable "cluster_dns_ipv4" {
  description = "Internal Service IPv4 address of core-dns."
  type        = string
  default     = "10.43.0.10"
}

variable "control_plane_nodepools" {
  description = "Number of control plane nodes."
  type = list(object({
    name         = string
    server_type  = string
    location     = string
    backups      = optional(bool)
    labels       = list(string)
    taints       = list(string)
    count        = number
    swap_size    = optional(string, "")
    zram_size    = optional(string, "")
    kubelet_args = optional(list(string), ["kube-reserved=cpu=250m,memory=1500Mi,ephemeral-storage=1Gi", "system-reserved=cpu=250m,memory=300Mi"])
  }))
  default = []
  validation {
    condition = length(
      [for control_plane_nodepool in var.control_plane_nodepools : control_plane_nodepool.name]
      ) == length(
      distinct(
        [for control_plane_nodepool in var.control_plane_nodepools : control_plane_nodepool.name]
      )
    )
    error_message = "Names in control_plane_nodepools must be unique."
  }
}

variable "agent_nodepools" {
  description = "Number of agent nodes."
  type = list(object({
    name                 = string
    server_type          = string
    location             = string
    backups              = optional(bool)
    floating_ip          = optional(bool)
    labels               = list(string)
    taints               = list(string)
    count                = number
    longhorn_volume_size = optional(number)
    swap_size            = optional(string, "")
    zram_size            = optional(string, "")
    kubelet_args         = optional(list(string), ["kube-reserved=cpu=50m,memory=300Mi,ephemeral-storage=1Gi", "system-reserved=cpu=250m,memory=300Mi"])
  }))
  default = []
  validation {
    condition = length(
      [for agent_nodepool in var.agent_nodepools : agent_nodepool.name]
      ) == length(
      distinct(
        [for agent_nodepool in var.agent_nodepools : agent_nodepool.name]
      )
    )
    error_message = "Names in agent_nodepools must be unique."
  }
}

variable "cluster_autoscaler_image" {
  type        = string
  default     = "ghcr.io/kube-hetzner/autoscaler/cluster-autoscaler"
  description = "Image of Kubernetes Cluster Autoscaler for Hetzner Cloud to be used."
}

variable "cluster_autoscaler_version" {
  type        = string
  default     = "20231027"
  description = "Version of Kubernetes Cluster Autoscaler for Hetzner Cloud. Should be aligned with Kubernetes version"
}

variable "cluster_autoscaler_log_level" {
  description = "Verbosity level of the logs for cluster-autoscaler"
  type        = number
  default     = 4

  validation {
    condition     = var.cluster_autoscaler_log_level >= 0 && var.cluster_autoscaler_log_level <= 5
    error_message = "The log level must be between 0 and 5."
  }
}

variable "cluster_autoscaler_log_to_stderr" {
  description = "Determines whether to log to stderr or not"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_stderr_threshold" {
  description = "Severity level above which logs are sent to stderr instead of stdout"
  type        = string
  default     = "INFO"

  validation {
    condition     = var.cluster_autoscaler_stderr_threshold == "INFO" || var.cluster_autoscaler_stderr_threshold == "WARNING" || var.cluster_autoscaler_stderr_threshold == "ERROR" || var.cluster_autoscaler_stderr_threshold == "FATAL"
    error_message = "The stderr threshold must be one of the following: INFO, WARNING, ERROR, FATAL."
  }
}

variable "cluster_autoscaler_extra_args" {
  type        = list(string)
  default     = []
  description = "Extra arguments for the Cluster Autoscaler deployment."
}

variable "autoscaler_nodepools" {
  description = "Cluster autoscaler nodepools."
  type = list(object({
    name        = string
    server_type = string
    location    = string
    min_nodes   = number
    max_nodes   = number
    labels      = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = []
}

variable "autoscaler_labels" {
  description = "Labels for nodes created by the Cluster Autoscaler."
  type        = list(string)
  default     = []
}

variable "autoscaler_taints" {
  description = "Taints for nodes created by the Cluster Autoscaler."
  type        = list(string)
  default     = []
}

variable "hetzner_ccm_version" {
  type        = string
  default     = null
  description = "Version of Kubernetes Cloud Controller Manager for Hetzner Cloud."
}

variable "allow_scheduling_on_control_plane" {
  type        = bool
  default     = false
  description = "Whether to allow non-control-plane workloads to run on the control-plane nodes."
}

variable "enable_metrics_server" {
  type        = bool
  default     = true
  description = "Whether to enable or disable k3s metric server."
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

variable "dns_servers" {
  type = list(string)

  default = [
    "185.12.64.1",
    "185.12.64.2",
    "2a01:4ff:ff00::add:1",
  ]
  description = "IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner. The length is limited to 3 entries, more entries is not supported by kubernetes"

  validation {
    condition     = length(var.dns_servers) <= 3
    error_message = "The list must have no more than 3 items."
  }
}

variable "address_for_connectivity_test" {
  type        = string
  default     = "1.1.1.1"
  description = "Before installing k3s, we actually verify that there is internet connectivity. By default we ping 1.1.1.1, but if you use a proxy, you may simply want to ping that proxy instead (assuming that the proxy has its own checks for internet connectivity)."
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

variable "postinstall_exec" {
  type        = list(string)
  default     = []
  description = "Additional to execute after the install calls, for example restoring a backup."
}


variable "extra_kustomize_deployment_commands" {
  type        = string
  default     = ""
  description = "Commands to be executed after the `kubectl apply -k <dir>` step."
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

variable "export_values" {
  type        = bool
  default     = false
  description = "Export for deployment used values.yaml-files as local files."
}

variable "control_planes_custom_config" {
  type        = any
  default     = {}
  description = "Custom control plane configuration e.g to allow etcd monitoring."
}

variable "additional_tls_sans" {
  description = "Additional TLS SANs to allow connection to control-plane through it."
  default     = []
  type        = list(string)
}
