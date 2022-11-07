<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.3 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 4.0.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | >= 1.35.2 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0.0 |
| <a name="requirement_remote"></a> [remote](#requirement\_remote) | >= 0.0.23 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | n/a |
| <a name="provider_github"></a> [github](#provider\_github) | >= 4.0.0 |
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | >= 1.35.2 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0.0 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_remote"></a> [remote](#provider\_remote) | >= 0.0.23 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_agents"></a> [agents](#module\_agents) | ./modules/host | n/a |
| <a name="module_control_planes"></a> [control\_planes](#module\_control\_planes) | ./modules/host | n/a |

### Resources

| Name | Type |
|------|------|
| [hcloud_firewall.k3s](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall) | resource |
| [hcloud_load_balancer.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer) | resource |
| [hcloud_load_balancer_network.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_network) | resource |
| [hcloud_load_balancer_service.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_service) | resource |
| [hcloud_load_balancer_target.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_target) | resource |
| [hcloud_network.k3s](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network) | resource |
| [hcloud_network_subnet.agent](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_network_subnet.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_placement_group.agent](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_placement_group.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_snapshot.autoscaler_image](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/snapshot) | resource |
| [hcloud_ssh_key.k3s](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/ssh_key) | resource |
| [hcloud_volume.longhorn_volume](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/volume) | resource |
| [local_file.kustomization_backup](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_sensitive_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [null_resource.agents](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.configure_autoscaler](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.configure_longhorn_volume](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.control_planes](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.destroy_cluster_loadbalancer](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.first_control_plane](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kustomization](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kustomization_user](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.k3s_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.rancher_bootstrap](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [cloudinit_config.autoscaler-config](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [github_release.hetzner_ccm](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [github_release.hetzner_csi](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [github_release.kured](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [hcloud_load_balancer.cluster](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/load_balancer) | data source |
| [hcloud_ssh_keys.keys_by_selector](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/ssh_keys) | data source |
| [remote_file.kubeconfig](https://registry.terraform.io/providers/tenstad/remote/latest/docs/data-sources/file) | data source |
| [remote_file.kustomization_backup](https://registry.terraform.io/providers/tenstad/remote/latest/docs/data-sources/file) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_nodepools"></a> [agent\_nodepools](#input\_agent\_nodepools) | Number of agent nodes. | `list(any)` | `[]` | no |
| <a name="input_allow_scheduling_on_control_plane"></a> [allow\_scheduling\_on\_control\_plane](#input\_allow\_scheduling\_on\_control\_plane) | Whether to allow non-control-plane workloads to run on the control-plane nodes. | `bool` | `false` | no |
| <a name="input_automatically_upgrade_k3s"></a> [automatically\_upgrade\_k3s](#input\_automatically\_upgrade\_k3s) | Whether to automatically upgrade k3s based on the selected channel. | `bool` | `true` | no |
| <a name="input_automatically_upgrade_os"></a> [automatically\_upgrade\_os](#input\_automatically\_upgrade\_os) | Whether to enable or disable automatic os updates. Defaults to true. Should be disabled for single-node clusters | `bool` | `true` | no |
| <a name="input_autoscaler_nodepools"></a> [autoscaler\_nodepools](#input\_autoscaler\_nodepools) | Cluster autoscaler nodepools. | <pre>list(object({<br>    name        = string<br>    server_type = string<br>    location    = string<br>    min_nodes   = number<br>    max_nodes   = number<br>  }))</pre> | `[]` | no |
| <a name="input_base_domain"></a> [base\_domain](#input\_base\_domain) | Base domain of the cluster, used for reserve dns. | `string` | `""` | no |
| <a name="input_block_icmp_ping_in"></a> [block\_icmp\_ping\_in](#input\_block\_icmp\_ping\_in) | Block entering ICMP ping. | `bool` | `false` | no |
| <a name="input_cert_manager_values"></a> [cert\_manager\_values](#input\_cert\_manager\_values) | Additional helm values file to pass to Cert-Manager as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_cilium_values"></a> [cilium\_values](#input\_cilium\_values) | Additional helm values file to pass to Cilium as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_cluster_autoscaler_image"></a> [cluster\_autoscaler\_image](#input\_cluster\_autoscaler\_image) | Image of Kubernetes Cluster Autoscaler for Hetzner Cloud to be used. | `string` | `"k8s.gcr.io/autoscaling/cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_version"></a> [cluster\_autoscaler\_version](#input\_cluster\_autoscaler\_version) | Version of Kubernetes Cluster Autoscaler for Hetzner Cloud. Should be aligned with Kubernetes version | `string` | `"v1.25.0"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster. | `string` | `"k3s"` | no |
| <a name="input_cni_plugin"></a> [cni\_plugin](#input\_cni\_plugin) | CNI plugin for k3s. | `string` | `"flannel"` | no |
| <a name="input_control_plane_nodepools"></a> [control\_plane\_nodepools](#input\_control\_plane\_nodepools) | Number of control plane nodes. | `list(any)` | `[]` | no |
| <a name="input_create_kubeconfig"></a> [create\_kubeconfig](#input\_create\_kubeconfig) | Create the kubeconfig as a local file resource. Should be disabled for automatic runs. | `bool` | `true` | no |
| <a name="input_create_kustomization"></a> [create\_kustomization](#input\_create\_kustomization) | Create the kustomization backup as a local file resource. Should be disabled for automatic runs. | `bool` | `true` | no |
| <a name="input_disable_hetzner_csi"></a> [disable\_hetzner\_csi](#input\_disable\_hetzner\_csi) | Disable hetzner csi driver. | `bool` | `false` | no |
| <a name="input_disable_network_policy"></a> [disable\_network\_policy](#input\_disable\_network\_policy) | Disable k3s default network policy controller (default false, automatically true for calico and cilium). | `bool` | `false` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | IP Addresses to use for the DNS Servers, set to an empty list to use the ones provided by Hetzner. | `list(string)` | <pre>[<br>  "1.1.1.1",<br>  " 1.0.0.1",<br>  "8.8.8.8"<br>]</pre> | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | Enable cert manager. | `bool` | `false` | no |
| <a name="input_enable_klipper_metal_lb"></a> [enable\_klipper\_metal\_lb](#input\_enable\_klipper\_metal\_lb) | Use klipper load balancer. | `bool` | `false` | no |
| <a name="input_enable_longhorn"></a> [enable\_longhorn](#input\_enable\_longhorn) | Whether of not to enable Longhorn. | `bool` | `false` | no |
| <a name="input_enable_metrics_server"></a> [enable\_metrics\_server](#input\_enable\_metrics\_server) | Whether to enable or disbale k3s mertric server. | `bool` | `true` | no |
| <a name="input_enable_nginx"></a> [enable\_nginx](#input\_enable\_nginx) | Whether to enable or disbale the installation of the Nginx Ingress Controller. | `bool` | `false` | no |
| <a name="input_enable_rancher"></a> [enable\_rancher](#input\_enable\_rancher) | Enable rancher. | `bool` | `false` | no |
| <a name="input_enable_traefik"></a> [enable\_traefik](#input\_enable\_traefik) | Whether to enable or disable the installation of the Traefik Ingress Controller. | `bool` | `true` | no |
| <a name="input_extra_firewall_rules"></a> [extra\_firewall\_rules](#input\_extra\_firewall\_rules) | Additional firewall rules to apply to the cluster. | `list(any)` | `[]` | no |
| <a name="input_extra_kustomize_parameters"></a> [extra\_kustomize\_parameters](#input\_extra\_kustomize\_parameters) | All values will be passed to the `kustomization.tmp.yml` template. | `map(any)` | `{}` | no |
| <a name="input_extra_packages_to_install"></a> [extra\_packages\_to\_install](#input\_extra\_packages\_to\_install) | A list of additional packages to install on nodes. | `list(string)` | `[]` | no |
| <a name="input_hcloud_ssh_key_id"></a> [hcloud\_ssh\_key\_id](#input\_hcloud\_ssh\_key\_id) | If passed, a key already registered within hetzner is used. Otherwise, a new one will be created by the module. | `string` | `null` | no |
| <a name="input_hcloud_token"></a> [hcloud\_token](#input\_hcloud\_token) | Hetzner Cloud API Token. | `string` | n/a | yes |
| <a name="input_hetzner_ccm_version"></a> [hetzner\_ccm\_version](#input\_hetzner\_ccm\_version) | Version of Kubernetes Cloud Controller Manager for Hetzner Cloud. | `string` | `null` | no |
| <a name="input_hetzner_csi_version"></a> [hetzner\_csi\_version](#input\_hetzner\_csi\_version) | Version of Container Storage Interface driver for Hetzner Cloud. | `string` | `null` | no |
| <a name="input_initial_k3s_channel"></a> [initial\_k3s\_channel](#input\_initial\_k3s\_channel) | Allows you to specify an initial k3s channel. | `string` | `"stable"` | no |
| <a name="input_kured_version"></a> [kured\_version](#input\_kured\_version) | Version of Kured | `string` | `null` | no |
| <a name="input_load_balancer_disable_ipv6"></a> [load\_balancer\_disable\_ipv6](#input\_load\_balancer\_disable\_ipv6) | Disable ipv6 for the load balancer. | `bool` | `false` | no |
| <a name="input_load_balancer_location"></a> [load\_balancer\_location](#input\_load\_balancer\_location) | Default load balancer location. | `string` | `"fsn1"` | no |
| <a name="input_load_balancer_type"></a> [load\_balancer\_type](#input\_load\_balancer\_type) | Default load balancer server type. | `string` | `"lb11"` | no |
| <a name="input_longhorn_fstype"></a> [longhorn\_fstype](#input\_longhorn\_fstype) | The longhorn fstype. | `string` | `"ext4"` | no |
| <a name="input_longhorn_replica_count"></a> [longhorn\_replica\_count](#input\_longhorn\_replica\_count) | Number of replicas per longhorn volume. | `number` | `3` | no |
| <a name="input_longhorn_values"></a> [longhorn\_values](#input\_longhorn\_values) | Additional helm values file to pass to longhorn as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_network_region"></a> [network\_region](#input\_network\_region) | Default region for network. | `string` | `"eu-central"` | no |
| <a name="input_nginx_ingress_values"></a> [nginx\_ingress\_values](#input\_nginx\_ingress\_values) | Additional helm values file to pass to nginx as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_placement_group_disable"></a> [placement\_group\_disable](#input\_placement\_group\_disable) | Whether to disable placement groups. | `bool` | `false` | no |
| <a name="input_rancher_bootstrap_password"></a> [rancher\_bootstrap\_password](#input\_rancher\_bootstrap\_password) | Rancher bootstrap password. | `string` | `""` | no |
| <a name="input_rancher_hostname"></a> [rancher\_hostname](#input\_rancher\_hostname) | The rancher hostname. | `string` | `""` | no |
| <a name="input_rancher_install_channel"></a> [rancher\_install\_channel](#input\_rancher\_install\_channel) | The rancher installation channel. | `string` | `"stable"` | no |
| <a name="input_rancher_registration_manifest_url"></a> [rancher\_registration\_manifest\_url](#input\_rancher\_registration\_manifest\_url) | The url of a rancher registration manifest to apply. (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/). | `string` | `""` | no |
| <a name="input_rancher_values"></a> [rancher\_values](#input\_rancher\_values) | Additional helm values file to pass to Rancher as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_ssh_additional_public_keys"></a> [ssh\_additional\_public\_keys](#input\_ssh\_additional\_public\_keys) | Additional SSH public Keys. Use them to grant other team members root access to your cluster nodes. | `list(string)` | `[]` | no |
| <a name="input_ssh_hcloud_key_label"></a> [ssh\_hcloud\_key\_label](#input\_ssh\_hcloud\_key\_label) | Additional SSH public Keys by hcloud label. e.g. role=admin | `string` | `""` | no |
| <a name="input_ssh_port"></a> [ssh\_port](#input\_ssh\_port) | The main SSH port to connect to the nodes. | `number` | `22` | no |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | SSH private Key. | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public Key. | `string` | n/a | yes |
| <a name="input_traefik_acme_email"></a> [traefik\_acme\_email](#input\_traefik\_acme\_email) | Email used to recieved expiration notice for certificate. | `string` | `""` | no |
| <a name="input_traefik_acme_tls"></a> [traefik\_acme\_tls](#input\_traefik\_acme\_tls) | Whether to include the TLS configuration with the Traefik configuration. | `bool` | `false` | no |
| <a name="input_traefik_additional_options"></a> [traefik\_additional\_options](#input\_traefik\_additional\_options) | Additional options to pass to Traefik as a list of strings. These are the ones that go into the additionalArguments section of the Traefik helm values file. | `list(string)` | `[]` | no |
| <a name="input_traefik_ingress_values"></a> [traefik\_ingress\_values](#input\_traefik\_ingress\_values) | Additional helm values file to pass to Traefik as 'valuesContent' at the HelmChart. | `string` | `""` | no |
| <a name="input_use_cluster_name_in_node_name"></a> [use\_cluster\_name\_in\_node\_name](#input\_use\_cluster\_name\_in\_node\_name) | Whether to use the cluster name in the node name. | `bool` | `true` | no |
| <a name="input_use_control_plane_lb"></a> [use\_control\_plane\_lb](#input\_use\_control\_plane\_lb) | When this is enabled, rather than the first node, all external traffic will be routed via a control-plane loadbalancer, allowing for high availability. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_agents_public_ipv4"></a> [agents\_public\_ipv4](#output\_agents\_public\_ipv4) | The public IPv4 addresses of the agent servers. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Shared suffix for all resources belonging to this cluster. |
| <a name="output_control_planes_public_ipv4"></a> [control\_planes\_public\_ipv4](#output\_control\_planes\_public\_ipv4) | The public IPv4 addresses of the controlplane servers. |
| <a name="output_ingress_public_ipv4"></a> [ingress\_public\_ipv4](#output\_ingress\_public\_ipv4) | The public ingress IPv4 of the cluster (external/internal load balancer) |
| <a name="output_ingress_public_ipv6"></a> [ingress\_public\_ipv6](#output\_ingress\_public\_ipv6) | The public ingress IPv6 of the cluster (external/internal load balancer). Only supported with external load balancer |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Structured kubeconfig data to supply to other providers |
| <a name="output_kubeconfig_file"></a> [kubeconfig\_file](#output\_kubeconfig\_file) | Kubeconfig file content with external IP address |
| <a name="output_load_balancer_public_ipv4"></a> [load\_balancer\_public\_ipv4](#output\_load\_balancer\_public\_ipv4) | The public IPv4 address of the Hetzner load balancer |
| <a name="output_load_balancer_public_ipv6"></a> [load\_balancer\_public\_ipv6](#output\_load\_balancer\_public\_ipv6) | The public IPv6 address of the Hetzner load balancer |
<!-- END_TF_DOCS -->
