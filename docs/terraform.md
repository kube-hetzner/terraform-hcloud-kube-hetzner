<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 6.4.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | >= 1.49.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.5.2 |
| <a name="requirement_remote"></a> [remote](#requirement\_remote) | >= 0.1.3 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | n/a |
| <a name="provider_github"></a> [github](#provider\_github) | >= 6.4.0 |
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | >= 1.49.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.5.2 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_remote"></a> [remote](#provider\_remote) | >= 0.1.3 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_agents"></a> [agents](#module\_agents) | ./modules/host | n/a |
| <a name="module_control_planes"></a> [control\_planes](#module\_control\_planes) | ./modules/host | n/a |

### Resources

| Name | Type |
|------|------|
| [hcloud_firewall.k3s](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall) | resource |
| [hcloud_floating_ip.agents](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/floating_ip) | resource |
| [hcloud_floating_ip_assignment.agents](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/floating_ip_assignment) | resource |
| [hcloud_load_balancer.cluster](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer) | resource |
| [hcloud_load_balancer.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer) | resource |
| [hcloud_load_balancer_network.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_network) | resource |
| [hcloud_load_balancer_service.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_service) | resource |
| [hcloud_load_balancer_target.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_target) | resource |
| [hcloud_network.k3s](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network) | resource |
| [hcloud_network_subnet.agent](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_network_subnet.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_placement_group.agent](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_placement_group.agent_named](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_placement_group.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_placement_group.control_plane_named](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_rdns.agents](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/rdns) | resource |
| [hcloud_ssh_key.k3s](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/ssh_key) | resource |
| [hcloud_volume.longhorn_volume](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/volume) | resource |
| [local_file.cert_manager_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.cilium_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.csi_driver_smb_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.haproxy_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.kustomization_backup](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.longhorn_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.nginx_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.traefik_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_sensitive_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [null_resource.agent_config](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.agents](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.authentication_config](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.autoscaled_nodes_registries](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.configure_autoscaler](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.configure_floating_ip](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.configure_longhorn_volume](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.control_plane_config](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.control_planes](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.first_control_plane](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kustomization](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kustomization_user](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kustomization_user_deploy](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.k3s_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.rancher_bootstrap](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [cloudinit_config.autoscaler_config](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.autoscaler_legacy_config](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [github_release.calico](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [github_release.hetzner_ccm](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [github_release.hetzner_csi](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [github_release.kured](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [hcloud_image.leapmicro_arm_snapshot](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/image) | data source |
| [hcloud_image.leapmicro_x86_snapshot](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/image) | data source |
| [hcloud_image.microos_arm_snapshot](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/image) | data source |
| [hcloud_image.microos_x86_snapshot](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/image) | data source |
| [hcloud_network.k3s](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/network) | data source |
| [hcloud_servers.autoscaled_nodes](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/servers) | data source |
| [hcloud_ssh_keys.keys_by_selector](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/ssh_keys) | data source |
| [remote_file.kubeconfig](https://registry.terraform.io/providers/tenstad/remote/latest/docs/data-sources/file) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_k3s_environment"></a> [additional\_k3s\_environment](#input\_additional\_k3s\_environment) | Additional environment variables for the k3s binary. See for example https://docs.k3s.io/advanced#configuring-an-http-proxy . | `map(any)` | `{}` | no |
| <a name="input_additional_tls_sans"></a> [additional\_tls\_sans](#input\_additional\_tls\_sans) | Additional TLS SANs to allow connection to control-plane through it. | `list(string)` | `[]` | no |
| <a name="input_address_for_connectivity_test"></a> [address\_for\_connectivity\_test](#input\_address\_for\_connectivity\_test) | Before installing k3s, we actually verify that there is internet connectivity. By default we ping 1.1.1.1, but if you use a proxy, you may simply want to ping that proxy instead (assuming that the proxy has its own checks for internet connectivity). | `string` | `"1.1.1.1"` | no |
| <a name="input_agent_nodepools"></a> [agent\_nodepools](#input\_agent\_nodepools) | Number of agent nodes. | <pre>list(object({<br/>    name                       = string<br/>    server_type                = string<br/>    location                   = string<br/>    backups                    = optional(bool)<br/>    floating_ip                = optional(bool)<br/>    floating_ip_rdns           = optional(string, null)<br/>    labels                     = list(string)<br/>    taints                     = list(string)<br/>    longhorn_volume_size       = optional(number)<br/>    swap_size                  = optional(string, "")<br/>    zram_size                  = optional(string, "")<br/>    kubelet_args               = optional(list(string), ["kube-reserved=cpu=50m,memory=300Mi,ephemeral-storage=1Gi", "system-reserved=cpu=250m,memory=300Mi"])<br/>    selinux                    = optional(bool, true)<br/>    placement_group_compat_idx = optional(number, 0)<br/>    placement_group            = optional(string, null)<br/>    os                         = optional(string, "microos")<br/>    count                      = optional(number, null)<br/>    nodes = optional(map(object({<br/>      server_type                = optional(string)<br/>      location                   = optional(string)<br/>      backups                    = optional(bool)<br/>      floating_ip                = optional(bool)<br/>      floating_ip_rdns           = optional(string, null)<br/>      labels                     = optional(list(string))<br/>      taints                     = optional(list(string))<br/>      longhorn_volume_size       = optional(number)<br/>      swap_size                  = optional(string, "")<br/>      zram_size                  = optional(string, "")<br/>      kubelet_args               = optional(list(string), ["kube-reserved=cpu=50m,memory=300Mi,ephemeral-storage=1Gi", "system-reserved=cpu=250m,memory=300Mi"])<br/>      selinux                    = optional(bool, true)<br/>      placement_group_compat_idx = optional(number, 0)<br/>      placement_group            = optional(string, null)<br/>      append_index_to_node_name  = optional(bool, true)<br/>      os                         = optional(string)<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_agent_nodes_custom_config"></a> [agent\_nodes\_custom\_config](#input\_agent\_nodes\_custom\_config) | Custom agent nodes configuration. | `any` | `{}` | no |
| <a name="input_allow_scheduling_on_control_plane"></a> [allow\_scheduling\_on\_control\_plane](#input\_allow\_scheduling\_on\_control\_plane) | Whether to allow non-control-plane workloads to run on the control-plane nodes. | `bool` | `false` | no |
| <a name="input_authentication_config"></a> [authentication\_config](#input\_authentication\_config) | Strucutred authentication configuration. This can be used to define external authentication providers. | `string` | `""` | no |
| <a name="input_automatically_upgrade_k3s"></a> [automatically\_upgrade\_k3s](#input\_automatically\_upgrade\_k3s) | Whether to automatically upgrade k3s based on the selected channel. | `bool` | `true` | no |
| <a name="input_automatically_upgrade_os"></a> [automatically\_upgrade\_os](#input\_automatically\_upgrade\_os) | Whether to enable or disable automatic os updates. Defaults to true. Should be disabled for single-node clusters | `bool` | `true` | no |
| <a name="input_autoscaler_labels"></a> [autoscaler\_labels](#input\_autoscaler\_labels) | Labels for nodes created by the Cluster Autoscaler. | `list(string)` | `[]` | no |
| <a name="input_autoscaler_nodepools"></a> [autoscaler\_nodepools](#input\_autoscaler\_nodepools) | Cluster autoscaler nodepools. | <pre>list(object({<br/>    name         = string<br/>    server_type  = string<br/>    location     = string<br/>    min_nodes    = number<br/>    max_nodes    = number<br/>    labels       = optional(map(string), {})<br/>    kubelet_args = optional(list(string), ["kube-reserved=cpu=50m,memory=300Mi,ephemeral-storage=1Gi", "system-reserved=cpu=250m,memory=300Mi"])<br/>    os           = optional(string, "microos")<br/>    taints = optional(list(object({<br/>      key    = string<br/>      value  = string<br/>      effect = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_autoscaler_taints"></a> [autoscaler\_taints](#input\_autoscaler\_taints) | Taints for nodes created by the Cluster Autoscaler. | `list(string)` | `[]` | no |
| <a name="input_base_domain"></a> [base\_domain](#input\_base\_domain) | Base domain of the cluster, used for reverse dns. | `string` | `""` | no |
| <a name="input_block_icmp_ping_in"></a> [block\_icmp\_ping\_in](#input\_block\_icmp\_ping\_in) | Block entering ICMP ping. | `bool` | `false` | no |
| <a name="input_calico_values"></a> [calico\_values](#input\_calico\_values) | Just a stub for a future helm implementation. Now it can be used to replace the calico kustomize patch of the calico manifest. | `string` | `""` | no |
| <a name="input_calico_version"></a> [calico\_version](#input\_calico\_version) | Version of Calico. See https://github.com/projectcalico/calico/releases for the available versions. | `string` | `null` | no |
| <a name="input_cert_manager_helmchart_bootstrap"></a> [cert\_manager\_helmchart\_bootstrap](#input\_cert\_manager\_helmchart\_bootstrap) | Whether the HelmChart cert\_manager shall be run on control-plane nodes. | `bool` | `false` | no |
| <a name="input_cert_manager_values"></a> [cert\_manager\_values](#input\_cert\_manager\_values) | Additional helm values file to pass to Cert-Manager as 'valuesContent' at the HelmChart. Warning, the default value is only valid from cert-manager v1.15.0 onwards. For older versions, you need to set 'installCRDs: true'. | `string` | `"crds:\n  enabled: true\n  keep: true\n"` | no |
| <a name="input_cert_manager_version"></a> [cert\_manager\_version](#input\_cert\_manager\_version) | Version of cert\_manager. | `string` | `"*"` | no |
| <a name="input_cilium_egress_gateway_enabled"></a> [cilium\_egress\_gateway\_enabled](#input\_cilium\_egress\_gateway\_enabled) | Enables egress gateway to redirect and SNAT the traffic that leaves the cluster. | `bool` | `false` | no |
| <a name="input_cilium_hubble_enabled"></a> [cilium\_hubble\_enabled](#input\_cilium\_hubble\_enabled) | Enables Hubble Observability to collect and visualize network traffic. | `bool` | `false` | no |
| <a name="input_cilium_hubble_metrics_enabled"></a> [cilium\_hubble\_metrics\_enabled](#input\_cilium\_hubble\_metrics\_enabled) | Configures the list of Hubble metrics to collect | `list(string)` | `[]` | no |
| <a name="input_cilium_ipv4_native_routing_cidr"></a> [cilium\_ipv4\_native\_routing\_cidr](#input\_cilium\_ipv4\_native\_routing\_cidr) | Used when Cilium is configured in native routing mode. The CNI assumes that the underlying network stack will forward packets to this destination without the need to apply SNAT. Default: value of "cluster\_ipv4\_cidr" | `string` | `null` | no |
| <a name="input_cilium_routing_mode"></a> [cilium\_routing\_mode](#input\_cilium\_routing\_mode) | Set native-routing mode ("native") or tunneling mode ("tunnel"). | `string` | `"tunnel"` | no |
| <a name="input_cilium_values"></a> [cilium\_values](#input\_cilium\_values) | Additional helm values file to pass to Cilium as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_cilium_version"></a> [cilium\_version](#input\_cilium\_version) | Version of Cilium. See https://github.com/cilium/cilium/releases for the available versions. | `string` | `"1.15.1"` | no |
| <a name="input_cluster_autoscaler_extra_args"></a> [cluster\_autoscaler\_extra\_args](#input\_cluster\_autoscaler\_extra\_args) | Extra arguments for the Cluster Autoscaler deployment. | `list(string)` | `[]` | no |
| <a name="input_cluster_autoscaler_image"></a> [cluster\_autoscaler\_image](#input\_cluster\_autoscaler\_image) | Image of Kubernetes Cluster Autoscaler for Hetzner Cloud to be used. | `string` | `"registry.k8s.io/autoscaling/cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_log_level"></a> [cluster\_autoscaler\_log\_level](#input\_cluster\_autoscaler\_log\_level) | Verbosity level of the logs for cluster-autoscaler | `number` | `4` | no |
| <a name="input_cluster_autoscaler_log_to_stderr"></a> [cluster\_autoscaler\_log\_to\_stderr](#input\_cluster\_autoscaler\_log\_to\_stderr) | Determines whether to log to stderr or not | `bool` | `true` | no |
| <a name="input_cluster_autoscaler_server_creation_timeout"></a> [cluster\_autoscaler\_server\_creation\_timeout](#input\_cluster\_autoscaler\_server\_creation\_timeout) | Timeout (in minutes) until which a newly created server/node has to become available before giving up and destroying it. | `number` | `15` | no |
| <a name="input_cluster_autoscaler_stderr_threshold"></a> [cluster\_autoscaler\_stderr\_threshold](#input\_cluster\_autoscaler\_stderr\_threshold) | Severity level above which logs are sent to stderr instead of stdout | `string` | `"INFO"` | no |
| <a name="input_cluster_autoscaler_version"></a> [cluster\_autoscaler\_version](#input\_cluster\_autoscaler\_version) | Version of Kubernetes Cluster Autoscaler for Hetzner Cloud. Should be aligned with Kubernetes version. Available versions for the official image can be found at https://explore.ggcr.dev/?repo=registry.k8s.io%2Fautoscaling%2Fcluster-autoscaler. | `string` | `"v1.31.5"` | no |
| <a name="input_cluster_dns_ipv4"></a> [cluster\_dns\_ipv4](#input\_cluster\_dns\_ipv4) | Internal Service IPv4 address of core-dns. | `string` | `"10.43.0.10"` | no |
| <a name="input_cluster_ipv4_cidr"></a> [cluster\_ipv4\_cidr](#input\_cluster\_ipv4\_cidr) | Internal Pod CIDR, used for the controller and currently for calico/cilium. | `string` | `"10.42.0.0/16"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster. | `string` | `"k3s"` | no |
| <a name="input_cni_plugin"></a> [cni\_plugin](#input\_cni\_plugin) | CNI plugin for k3s. | `string` | `"flannel"` | no |
| <a name="input_control_plane_lb_enable_public_interface"></a> [control\_plane\_lb\_enable\_public\_interface](#input\_control\_plane\_lb\_enable\_public\_interface) | Enable or disable public interface for the control plane load balancer . Defaults to true. | `bool` | `true` | no |
| <a name="input_control_plane_lb_type"></a> [control\_plane\_lb\_type](#input\_control\_plane\_lb\_type) | The type of load balancer to use for the control plane load balancer. Defaults to lb11, which is the cheapest one. | `string` | `"lb11"` | no |
| <a name="input_control_plane_nodepools"></a> [control\_plane\_nodepools](#input\_control\_plane\_nodepools) | Number of control plane nodes. | <pre>list(object({<br/>    name                       = string<br/>    server_type                = string<br/>    location                   = string<br/>    backups                    = optional(bool)<br/>    labels                     = list(string)<br/>    taints                     = list(string)<br/>    count                      = number<br/>    swap_size                  = optional(string, "")<br/>    zram_size                  = optional(string, "")<br/>    kubelet_args               = optional(list(string), ["kube-reserved=cpu=250m,memory=1500Mi,ephemeral-storage=1Gi", "system-reserved=cpu=250m,memory=300Mi"])<br/>    selinux                    = optional(bool, true)<br/>    placement_group_compat_idx = optional(number, 0)<br/>    placement_group            = optional(string, null)<br/>    os                         = optional(string, "microos")<br/>  }))</pre> | `[]` | no |
| <a name="input_control_planes_custom_config"></a> [control\_planes\_custom\_config](#input\_control\_planes\_custom\_config) | Custom control plane configuration e.g to allow etcd monitoring. | `any` | `{}` | no |
| <a name="input_create_kubeconfig"></a> [create\_kubeconfig](#input\_create\_kubeconfig) | Create the kubeconfig as a local file resource. Should be disabled for automatic runs. | `bool` | `true` | no |
| <a name="input_create_kustomization"></a> [create\_kustomization](#input\_create\_kustomization) | Create the kustomization backup as a local file resource. Should be disabled for automatic runs. | `bool` | `true` | no |
| <a name="input_csi_driver_smb_helmchart_bootstrap"></a> [csi\_driver\_smb\_helmchart\_bootstrap](#input\_csi\_driver\_smb\_helmchart\_bootstrap) | Whether the HelmChart csi\_driver\_smb shall be run on control-plane nodes. | `bool` | `false` | no |
| <a name="input_csi_driver_smb_values"></a> [csi\_driver\_smb\_values](#input\_csi\_driver\_smb\_values) | Additional helm values file to pass to csi-driver-smb as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_csi_driver_smb_version"></a> [csi\_driver\_smb\_version](#input\_csi\_driver\_smb\_version) | Version of csi\_driver\_smb. See https://github.com/kubernetes-csi/csi-driver-smb/releases for the available versions. | `string` | `"*"` | no |
| <a name="input_disable_hetzner_csi"></a> [disable\_hetzner\_csi](#input\_disable\_hetzner\_csi) | Disable hetzner csi driver. | `bool` | `false` | no |
| <a name="input_disable_kube_proxy"></a> [disable\_kube\_proxy](#input\_disable\_kube\_proxy) | Disable kube-proxy in K3s (default false). | `bool` | `false` | no |
| <a name="input_disable_network_policy"></a> [disable\_network\_policy](#input\_disable\_network\_policy) | Disable k3s default network policy controller (default false, automatically true for calico and cilium). | `bool` | `false` | no |
| <a name="input_disable_selinux"></a> [disable\_selinux](#input\_disable\_selinux) | Disable SELinux on all nodes. | `bool` | `false` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner. The length is limited to 3 entries, more entries is not supported by kubernetes | `list(string)` | <pre>[<br/>  "185.12.64.1",<br/>  "185.12.64.2",<br/>  "2a01:4ff:ff00::add:1"<br/>]</pre> | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | Enable cert manager. | `bool` | `true` | no |
| <a name="input_enable_csi_driver_smb"></a> [enable\_csi\_driver\_smb](#input\_enable\_csi\_driver\_smb) | Whether or not to enable csi-driver-smb. | `bool` | `false` | no |
| <a name="input_enable_delete_protection"></a> [enable\_delete\_protection](#input\_enable\_delete\_protection) | Enable or disable delete protection for resources in Hetzner Cloud. | <pre>object({<br/>    floating_ip   = optional(bool, false)<br/>    load_balancer = optional(bool, false)<br/>    volume        = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "floating_ip": false,<br/>  "load_balancer": false,<br/>  "volume": false<br/>}</pre> | no |
| <a name="input_enable_iscsid"></a> [enable\_iscsid](#input\_enable\_iscsid) | This is always true when enable\_longhorn=true, however, you may also want this enabled if you perform your own installation of longhorn after this module runs. | `bool` | `false` | no |
| <a name="input_enable_klipper_metal_lb"></a> [enable\_klipper\_metal\_lb](#input\_enable\_klipper\_metal\_lb) | Use klipper load balancer. | `bool` | `false` | no |
| <a name="input_enable_local_storage"></a> [enable\_local\_storage](#input\_enable\_local\_storage) | Whether to enable or disable k3s local-storage. Warning: when enabled, there will be two default storage classes: "local-path" and "hcloud-volumes"! | `bool` | `false` | no |
| <a name="input_enable_longhorn"></a> [enable\_longhorn](#input\_enable\_longhorn) | Whether or not to enable Longhorn. | `bool` | `false` | no |
| <a name="input_enable_metrics_server"></a> [enable\_metrics\_server](#input\_enable\_metrics\_server) | Whether to enable or disable k3s metric server. | `bool` | `true` | no |
| <a name="input_enable_rancher"></a> [enable\_rancher](#input\_enable\_rancher) | Enable rancher. | `bool` | `false` | no |
| <a name="input_enable_wireguard"></a> [enable\_wireguard](#input\_enable\_wireguard) | Use wireguard-native as the backend for CNI. | `bool` | `false` | no |
| <a name="input_etcd_s3_backup"></a> [etcd\_s3\_backup](#input\_etcd\_s3\_backup) | Etcd cluster state backup to S3 storage | `map(any)` | `{}` | no |
| <a name="input_existing_network_id"></a> [existing\_network\_id](#input\_existing\_network\_id) | If you want to create the private network before calling this module, you can do so and pass its id here. NOTE: make sure to adapt network\_ipv4\_cidr accordingly to a range which does not collide with your other nodes. | `list(string)` | `[]` | no |
| <a name="input_export_values"></a> [export\_values](#input\_export\_values) | Export for deployment used values.yaml-files as local files. | `bool` | `false` | no |
| <a name="input_extra_firewall_rules"></a> [extra\_firewall\_rules](#input\_extra\_firewall\_rules) | Additional firewall rules to apply to the cluster. | `list(any)` | `[]` | no |
| <a name="input_extra_kustomize_deployment_commands"></a> [extra\_kustomize\_deployment\_commands](#input\_extra\_kustomize\_deployment\_commands) | Commands to be executed after the `kubectl apply -k <dir>` step. | `string` | `""` | no |
| <a name="input_extra_kustomize_parameters"></a> [extra\_kustomize\_parameters](#input\_extra\_kustomize\_parameters) | All values will be passed to the `kustomization.tmp.yml` template. | `map(any)` | `{}` | no |
| <a name="input_firewall_kube_api_source"></a> [firewall\_kube\_api\_source](#input\_firewall\_kube\_api\_source) | Source networks that have Kube API access to the servers. | `list(string)` | <pre>[<br/>  "0.0.0.0/0",<br/>  "::/0"<br/>]</pre> | no |
| <a name="input_firewall_ssh_source"></a> [firewall\_ssh\_source](#input\_firewall\_ssh\_source) | Source networks that have SSH access to the servers. | `list(string)` | <pre>[<br/>  "0.0.0.0/0",<br/>  "::/0"<br/>]</pre> | no |
| <a name="input_haproxy_additional_proxy_protocol_ips"></a> [haproxy\_additional\_proxy\_protocol\_ips](#input\_haproxy\_additional\_proxy\_protocol\_ips) | Additional trusted proxy protocol IPs to pass to haproxy. | `list(string)` | `[]` | no |
| <a name="input_haproxy_requests_cpu"></a> [haproxy\_requests\_cpu](#input\_haproxy\_requests\_cpu) | Setting for HAProxy controller.resources.requests.cpu | `string` | `"250m"` | no |
| <a name="input_haproxy_requests_memory"></a> [haproxy\_requests\_memory](#input\_haproxy\_requests\_memory) | Setting for HAProxy controller.resources.requests.memory | `string` | `"400Mi"` | no |
| <a name="input_haproxy_values"></a> [haproxy\_values](#input\_haproxy\_values) | Helm values file to pass to haproxy as 'valuesContent' at the HelmChart, overriding the default. | `string` | `""` | no |
| <a name="input_haproxy_version"></a> [haproxy\_version](#input\_haproxy\_version) | Version of HAProxy helm chart. | `string` | `""` | no |
| <a name="input_hcloud_ssh_key_id"></a> [hcloud\_ssh\_key\_id](#input\_hcloud\_ssh\_key\_id) | If passed, a key already registered within hetzner is used. Otherwise, a new one will be created by the module. | `string` | `null` | no |
| <a name="input_hcloud_token"></a> [hcloud\_token](#input\_hcloud\_token) | Hetzner Cloud API Token. | `string` | n/a | yes |
| <a name="input_hetzner_ccm_version"></a> [hetzner\_ccm\_version](#input\_hetzner\_ccm\_version) | Version of Kubernetes Cloud Controller Manager for Hetzner Cloud. See https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases for the available versions. | `string` | `null` | no |
| <a name="input_hetzner_csi_values"></a> [hetzner\_csi\_values](#input\_hetzner\_csi\_values) | Additional helm values file to pass to hetzner csi as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_hetzner_csi_version"></a> [hetzner\_csi\_version](#input\_hetzner\_csi\_version) | Version of Container Storage Interface driver for Hetzner Cloud. See https://github.com/hetznercloud/csi-driver/releases for the available versions. | `string` | `null` | no |
| <a name="input_ingress_controller"></a> [ingress\_controller](#input\_ingress\_controller) | The name of the ingress controller. | `string` | `"traefik"` | no |
| <a name="input_ingress_max_replica_count"></a> [ingress\_max\_replica\_count](#input\_ingress\_max\_replica\_count) | Number of maximum replicas per ingress controller. Used for ingress HPA. Must be higher than number of replicas. | `number` | `10` | no |
| <a name="input_ingress_replica_count"></a> [ingress\_replica\_count](#input\_ingress\_replica\_count) | Number of replicas per ingress controller. 0 means autodetect based on the number of agent nodes. | `number` | `0` | no |
| <a name="input_ingress_target_namespace"></a> [ingress\_target\_namespace](#input\_ingress\_target\_namespace) | The namespace to deploy the ingress controller to. Defaults to ingress name. | `string` | `""` | no |
| <a name="input_initial_k3s_channel"></a> [initial\_k3s\_channel](#input\_initial\_k3s\_channel) | Allows you to specify an initial k3s channel. See https://update.k3s.io/v1-release/channels for available channels. | `string` | `"v1.31"` | no |
| <a name="input_install_k3s_version"></a> [install\_k3s\_version](#input\_install\_k3s\_version) | Allows you to specify the k3s version (Example: v1.29.6+k3s2). Supersedes initial\_k3s\_channel. See https://github.com/k3s-io/k3s/releases for available versions. | `string` | `""` | no |
| <a name="input_k3s_agent_kubelet_args"></a> [k3s\_agent\_kubelet\_args](#input\_k3s\_agent\_kubelet\_args) | Kubelet args for agent nodes. | `list(string)` | `[]` | no |
| <a name="input_k3s_autoscaler_kubelet_args"></a> [k3s\_autoscaler\_kubelet\_args](#input\_k3s\_autoscaler\_kubelet\_args) | Kubelet args for autoscaler nodes. | `list(string)` | `[]` | no |
| <a name="input_k3s_control_plane_kubelet_args"></a> [k3s\_control\_plane\_kubelet\_args](#input\_k3s\_control\_plane\_kubelet\_args) | Kubelet args for control plane nodes. | `list(string)` | `[]` | no |
| <a name="input_k3s_exec_agent_args"></a> [k3s\_exec\_agent\_args](#input\_k3s\_exec\_agent\_args) | Agents nodes are started with `k3s agent {k3s_exec_agent_args}`. Use this to add kubelet-arg for example. | `string` | `""` | no |
| <a name="input_k3s_exec_server_args"></a> [k3s\_exec\_server\_args](#input\_k3s\_exec\_server\_args) | The control plane is started with `k3s server {k3s_exec_server_args}`. Use this to add kube-apiserver-arg for example. | `string` | `""` | no |
| <a name="input_k3s_global_kubelet_args"></a> [k3s\_global\_kubelet\_args](#input\_k3s\_global\_kubelet\_args) | Global kubelet args for all nodes. | `list(string)` | `[]` | no |
| <a name="input_k3s_registries"></a> [k3s\_registries](#input\_k3s\_registries) | K3S registries.yml contents. It used to access private docker registries. | `string` | `" "` | no |
| <a name="input_k3s_token"></a> [k3s\_token](#input\_k3s\_token) | k3s master token (must match when restoring a cluster). | `string` | `null` | no |
| <a name="input_keep_disk_agents"></a> [keep\_disk\_agents](#input\_keep\_disk\_agents) | Whether to keep OS disks of nodes the same size when upgrading an agent node | `bool` | `false` | no |
| <a name="input_keep_disk_cp"></a> [keep\_disk\_cp](#input\_keep\_disk\_cp) | Whether to keep OS disks of nodes the same size when upgrading a control-plane node | `bool` | `false` | no |
| <a name="input_kubeconfig_server_address"></a> [kubeconfig\_server\_address](#input\_kubeconfig\_server\_address) | The hostname used for kubeconfig. | `string` | `""` | no |
| <a name="input_kured_options"></a> [kured\_options](#input\_kured\_options) | n/a | `map(string)` | `{}` | no |
| <a name="input_kured_version"></a> [kured\_version](#input\_kured\_version) | Version of Kured. See https://github.com/kubereboot/kured/releases for the available versions. | `string` | `null` | no |
| <a name="input_lb_hostname"></a> [lb\_hostname](#input\_lb\_hostname) | The Hetzner Load Balancer hostname, for either Traefik, HAProxy or Ingress-Nginx. | `string` | `""` | no |
| <a name="input_load_balancer_algorithm_type"></a> [load\_balancer\_algorithm\_type](#input\_load\_balancer\_algorithm\_type) | Specifies the algorithm type of the load balancer. | `string` | `"round_robin"` | no |
| <a name="input_load_balancer_disable_ipv6"></a> [load\_balancer\_disable\_ipv6](#input\_load\_balancer\_disable\_ipv6) | Disable IPv6 for the load balancer. | `bool` | `false` | no |
| <a name="input_load_balancer_disable_public_network"></a> [load\_balancer\_disable\_public\_network](#input\_load\_balancer\_disable\_public\_network) | Disables the public network of the load balancer. | `bool` | `false` | no |
| <a name="input_load_balancer_health_check_interval"></a> [load\_balancer\_health\_check\_interval](#input\_load\_balancer\_health\_check\_interval) | Specifies the interval at which a health check is performed. Minimum is 3s. | `string` | `"15s"` | no |
| <a name="input_load_balancer_health_check_retries"></a> [load\_balancer\_health\_check\_retries](#input\_load\_balancer\_health\_check\_retries) | Specifies the number of times a health check is retried before a target is marked as unhealthy. | `number` | `3` | no |
| <a name="input_load_balancer_health_check_timeout"></a> [load\_balancer\_health\_check\_timeout](#input\_load\_balancer\_health\_check\_timeout) | Specifies the timeout of a single health check. Must not be greater than the health check interval. Minimum is 1s. | `string` | `"10s"` | no |
| <a name="input_load_balancer_location"></a> [load\_balancer\_location](#input\_load\_balancer\_location) | Default load balancer location. | `string` | `"fsn1"` | no |
| <a name="input_load_balancer_type"></a> [load\_balancer\_type](#input\_load\_balancer\_type) | Default load balancer server type. | `string` | `"lb11"` | no |
| <a name="input_longhorn_fstype"></a> [longhorn\_fstype](#input\_longhorn\_fstype) | The longhorn fstype. | `string` | `"ext4"` | no |
| <a name="input_longhorn_helmchart_bootstrap"></a> [longhorn\_helmchart\_bootstrap](#input\_longhorn\_helmchart\_bootstrap) | Whether the HelmChart longhorn shall be run on control-plane nodes. | `bool` | `false` | no |
| <a name="input_longhorn_namespace"></a> [longhorn\_namespace](#input\_longhorn\_namespace) | Namespace for longhorn deployment, defaults to 'longhorn-system' | `string` | `"longhorn-system"` | no |
| <a name="input_longhorn_replica_count"></a> [longhorn\_replica\_count](#input\_longhorn\_replica\_count) | Number of replicas per longhorn volume. | `number` | `3` | no |
| <a name="input_longhorn_repository"></a> [longhorn\_repository](#input\_longhorn\_repository) | By default the official chart which may be incompatible with rancher is used. If you need to fully support rancher switch to https://charts.rancher.io. | `string` | `"https://charts.longhorn.io"` | no |
| <a name="input_longhorn_values"></a> [longhorn\_values](#input\_longhorn\_values) | Additional helm values file to pass to longhorn as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_longhorn_version"></a> [longhorn\_version](#input\_longhorn\_version) | Version of longhorn. | `string` | `"*"` | no |
| <a name="input_microos_arm_snapshot_id"></a> [microos\_arm\_snapshot\_id](#input\_microos\_arm\_snapshot\_id) | MicroOS ARM snapshot ID to be used. Per default empty, the most recent image created using createkh will be used | `string` | `""` | no |
| <a name="input_microos_x86_snapshot_id"></a> [microos\_x86\_snapshot\_id](#input\_microos\_x86\_snapshot\_id) | MicroOS x86 snapshot ID to be used. Per default empty, the most recent image created using createkh will be used | `string` | `""` | no |
| <a name="input_network_ipv4_cidr"></a> [network\_ipv4\_cidr](#input\_network\_ipv4\_cidr) | The main network cidr that all subnets will be created upon. | `string` | `"10.0.0.0/8"` | no |
| <a name="input_network_region"></a> [network\_region](#input\_network\_region) | Default region for network. | `string` | `"eu-central"` | no |
| <a name="input_nginx_values"></a> [nginx\_values](#input\_nginx\_values) | Additional helm values file to pass to nginx as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_nginx_version"></a> [nginx\_version](#input\_nginx\_version) | Version of Nginx helm chart. See https://github.com/kubernetes/ingress-nginx?tab=readme-ov-file#supported-versions-table for the available versions. | `string` | `""` | no |
| <a name="input_placement_group_disable"></a> [placement\_group\_disable](#input\_placement\_group\_disable) | Whether to disable placement groups. | `bool` | `false` | no |
| <a name="input_postinstall_exec"></a> [postinstall\_exec](#input\_postinstall\_exec) | Additional to execute after the install calls, for example restoring a backup. | `list(string)` | `[]` | no |
| <a name="input_preinstall_exec"></a> [preinstall\_exec](#input\_preinstall\_exec) | Additional to execute before the install calls, for example fetching and installing certs. | `list(string)` | `[]` | no |
| <a name="input_rancher_bootstrap_password"></a> [rancher\_bootstrap\_password](#input\_rancher\_bootstrap\_password) | Rancher bootstrap password. | `string` | `""` | no |
| <a name="input_rancher_helmchart_bootstrap"></a> [rancher\_helmchart\_bootstrap](#input\_rancher\_helmchart\_bootstrap) | Whether the HelmChart rancher shall be run on control-plane nodes. | `bool` | `false` | no |
| <a name="input_rancher_hostname"></a> [rancher\_hostname](#input\_rancher\_hostname) | The rancher hostname. | `string` | `""` | no |
| <a name="input_rancher_install_channel"></a> [rancher\_install\_channel](#input\_rancher\_install\_channel) | The rancher installation channel. | `string` | `"stable"` | no |
| <a name="input_rancher_registration_manifest_url"></a> [rancher\_registration\_manifest\_url](#input\_rancher\_registration\_manifest\_url) | The url of a rancher registration manifest to apply. (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/). | `string` | `""` | no |
| <a name="input_rancher_values"></a> [rancher\_values](#input\_rancher\_values) | Additional helm values file to pass to Rancher as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_rancher_version"></a> [rancher\_version](#input\_rancher\_version) | Version of rancher. | `string` | `"*"` | no |
| <a name="input_restrict_outbound_traffic"></a> [restrict\_outbound\_traffic](#input\_restrict\_outbound\_traffic) | Whether or not to restrict the outbound traffic. | `bool` | `true` | no |
| <a name="input_service_ipv4_cidr"></a> [service\_ipv4\_cidr](#input\_service\_ipv4\_cidr) | Internal Service CIDR, used for the controller and currently for calico/cilium. | `string` | `"10.43.0.0/16"` | no |
| <a name="input_ssh_additional_public_keys"></a> [ssh\_additional\_public\_keys](#input\_ssh\_additional\_public\_keys) | Additional SSH public Keys. Use them to grant other team members root access to your cluster nodes. | `list(string)` | `[]` | no |
| <a name="input_ssh_hcloud_key_label"></a> [ssh\_hcloud\_key\_label](#input\_ssh\_hcloud\_key\_label) | Additional SSH public Keys by hcloud label. e.g. role=admin | `string` | `""` | no |
| <a name="input_ssh_max_auth_tries"></a> [ssh\_max\_auth\_tries](#input\_ssh\_max\_auth\_tries) | The maximum number of authentication attempts permitted per connection. | `number` | `2` | no |
| <a name="input_ssh_port"></a> [ssh\_port](#input\_ssh\_port) | The main SSH port to connect to the nodes. | `number` | `22` | no |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | SSH private Key. | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public Key. | `string` | n/a | yes |
| <a name="input_sys_upgrade_controller_version"></a> [sys\_upgrade\_controller\_version](#input\_sys\_upgrade\_controller\_version) | Version of the System Upgrade Controller for automated upgrades of k3s. See https://github.com/rancher/system-upgrade-controller/releases for the available versions. | `string` | `"v0.14.2"` | no |
| <a name="input_system_upgrade_enable_eviction"></a> [system\_upgrade\_enable\_eviction](#input\_system\_upgrade\_enable\_eviction) | Whether to directly delete pods during system upgrade (k3s) or evict them. Defaults to true. Disable this on small clusters to avoid system upgrades hanging since pods resisting eviction keep node unschedulable forever. NOTE: turning this off, introduces potential downtime of services of the upgraded nodes. | `bool` | `true` | no |
| <a name="input_system_upgrade_use_drain"></a> [system\_upgrade\_use\_drain](#input\_system\_upgrade\_use\_drain) | Wether using drain (true, the default), which will deletes and transfers all pods to other nodes before a node is being upgraded, or cordon (false), which just prevents schedulung new pods on the node during upgrade and keeps all pods running | `bool` | `true` | no |
| <a name="input_traefik_additional_options"></a> [traefik\_additional\_options](#input\_traefik\_additional\_options) | Additional options to pass to Traefik as a list of strings. These are the ones that go into the additionalArguments section of the Traefik helm values file. | `list(string)` | `[]` | no |
| <a name="input_traefik_additional_ports"></a> [traefik\_additional\_ports](#input\_traefik\_additional\_ports) | Additional ports to pass to Traefik. These are the ones that go into the ports section of the Traefik helm values file. | <pre>list(object({<br/>    name        = string<br/>    port        = number<br/>    exposedPort = number<br/>  }))</pre> | `[]` | no |
| <a name="input_traefik_additional_trusted_ips"></a> [traefik\_additional\_trusted\_ips](#input\_traefik\_additional\_trusted\_ips) | Additional Trusted IPs to pass to Traefik. These are the ones that go into the trustedIPs section of the Traefik helm values file. | `list(string)` | `[]` | no |
| <a name="input_traefik_autoscaling"></a> [traefik\_autoscaling](#input\_traefik\_autoscaling) | Should traefik enable Horizontal Pod Autoscaler. | `bool` | `true` | no |
| <a name="input_traefik_image_tag"></a> [traefik\_image\_tag](#input\_traefik\_image\_tag) | Traefik image tag. Useful to use the beta version for new features. Example: v3.0.0-beta5 | `string` | `""` | no |
| <a name="input_traefik_pod_disruption_budget"></a> [traefik\_pod\_disruption\_budget](#input\_traefik\_pod\_disruption\_budget) | Should traefik enable pod disruption budget. Default values are maxUnavailable: 33% and minAvailable: 1. | `bool` | `true` | no |
| <a name="input_traefik_redirect_to_https"></a> [traefik\_redirect\_to\_https](#input\_traefik\_redirect\_to\_https) | Should traefik redirect http traffic to https. | `bool` | `true` | no |
| <a name="input_traefik_resource_limits"></a> [traefik\_resource\_limits](#input\_traefik\_resource\_limits) | Should traefik enable default resource requests and limits. Default values are requests: 100m & 50Mi and limits: 300m & 150Mi. | `bool` | `true` | no |
| <a name="input_traefik_resource_values"></a> [traefik\_resource\_values](#input\_traefik\_resource\_values) | Requests and limits for Traefik. | <pre>object({<br/>    requests = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>    limits = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "cpu": "300m",<br/>    "memory": "150Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "50Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_traefik_values"></a> [traefik\_values](#input\_traefik\_values) | Additional helm values file to pass to Traefik as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_traefik_version"></a> [traefik\_version](#input\_traefik\_version) | Version of Traefik helm chart. See https://github.com/traefik/traefik-helm-chart/releases for the available versions. | `string` | `""` | no |
| <a name="input_use_cluster_name_in_node_name"></a> [use\_cluster\_name\_in\_node\_name](#input\_use\_cluster\_name\_in\_node\_name) | Whether to use the cluster name in the node name. | `bool` | `true` | no |
| <a name="input_use_control_plane_lb"></a> [use\_control\_plane\_lb](#input\_use\_control\_plane\_lb) | When this is enabled, rather than the first node, all external traffic will be routed via a control-plane loadbalancer, allowing for high availability. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_agent_nodes"></a> [agent\_nodes](#output\_agent\_nodes) | The agent nodes |
| <a name="output_agents_public_ipv4"></a> [agents\_public\_ipv4](#output\_agents\_public\_ipv4) | The public IPv4 addresses of the agent servers. |
| <a name="output_agents_public_ipv6"></a> [agents\_public\_ipv6](#output\_agents\_public\_ipv6) | The public IPv6 addresses of the agent servers. |
| <a name="output_cert_manager_values"></a> [cert\_manager\_values](#output\_cert\_manager\_values) | Helm values.yaml used for cert-manager |
| <a name="output_cilium_values"></a> [cilium\_values](#output\_cilium\_values) | Helm values.yaml used for Cilium |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Shared suffix for all resources belonging to this cluster. |
| <a name="output_control_plane_nodes"></a> [control\_plane\_nodes](#output\_control\_plane\_nodes) | The control plane nodes |
| <a name="output_control_planes_public_ipv4"></a> [control\_planes\_public\_ipv4](#output\_control\_planes\_public\_ipv4) | The public IPv4 addresses of the controlplane servers. |
| <a name="output_control_planes_public_ipv6"></a> [control\_planes\_public\_ipv6](#output\_control\_planes\_public\_ipv6) | The public IPv6 addresses of the controlplane servers. |
| <a name="output_csi_driver_smb_values"></a> [csi\_driver\_smb\_values](#output\_csi\_driver\_smb\_values) | Helm values.yaml used for SMB CSI driver |
| <a name="output_haproxy_values"></a> [haproxy\_values](#output\_haproxy\_values) | Helm values.yaml used for HAProxy |
| <a name="output_ingress_public_ipv4"></a> [ingress\_public\_ipv4](#output\_ingress\_public\_ipv4) | The public IPv4 address of the Hetzner load balancer (with fallback to first control plane node) |
| <a name="output_ingress_public_ipv6"></a> [ingress\_public\_ipv6](#output\_ingress\_public\_ipv6) | The public IPv6 address of the Hetzner load balancer (with fallback to first control plane node) |
| <a name="output_k3s_endpoint"></a> [k3s\_endpoint](#output\_k3s\_endpoint) | A controller endpoint to register new nodes |
| <a name="output_k3s_token"></a> [k3s\_token](#output\_k3s\_token) | The k3s token to register new nodes |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig file content with external IP address |
| <a name="output_kubeconfig_data"></a> [kubeconfig\_data](#output\_kubeconfig\_data) | Structured kubeconfig data to supply to other providers |
| <a name="output_kubeconfig_file"></a> [kubeconfig\_file](#output\_kubeconfig\_file) | Kubeconfig file content with external IP address |
| <a name="output_lb_control_plane_ipv4"></a> [lb\_control\_plane\_ipv4](#output\_lb\_control\_plane\_ipv4) | The public IPv4 address of the Hetzner control plane load balancer |
| <a name="output_lb_control_plane_ipv6"></a> [lb\_control\_plane\_ipv6](#output\_lb\_control\_plane\_ipv6) | The public IPv6 address of the Hetzner control plane load balancer |
| <a name="output_longhorn_values"></a> [longhorn\_values](#output\_longhorn\_values) | Helm values.yaml used for Longhorn |
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | The ID of the HCloud network. |
| <a name="output_nginx_values"></a> [nginx\_values](#output\_nginx\_values) | Helm values.yaml used for nginx-ingress |
| <a name="output_ssh_key_id"></a> [ssh\_key\_id](#output\_ssh\_key\_id) | The ID of the HCloud SSH key. |
| <a name="output_traefik_values"></a> [traefik\_values](#output\_traefik\_values) | Helm values.yaml used for Traefik |
<!-- END_TF_DOCS -->