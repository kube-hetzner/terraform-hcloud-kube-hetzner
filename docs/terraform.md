<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 4.0.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | >= 1.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0.0 |
| <a name="requirement_remote"></a> [remote](#requirement\_remote) | >= 0.0.23 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | >= 4.0.0 |
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | >= 1.0.0 |
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
| [hcloud_network.k3s](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network) | resource |
| [hcloud_network_subnet.agent](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_network_subnet.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_placement_group.agent](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_placement_group.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_ssh_key.k3s](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/ssh_key) | resource |
| [local_file.kustomization_backup](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_sensitive_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [null_resource.agents](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.control_planes](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.destroy_traefik_loadbalancer](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.first_control_plane](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kustomization](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.k3s_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [github_release.hetzner_ccm](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [github_release.hetzner_csi](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [github_release.kured](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/release) | data source |
| [hcloud_load_balancer.traefik](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/load_balancer) | data source |
| [remote_file.kubeconfig](https://registry.terraform.io/providers/tenstad/remote/latest/docs/data-sources/file) | data source |
| [remote_file.kustomization_backup](https://registry.terraform.io/providers/tenstad/remote/latest/docs/data-sources/file) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_nodepools"></a> [agent\_nodepools](#input\_agent\_nodepools) | Number of agent nodes. | `list(any)` | `[]` | no |
| <a name="input_allow_scheduling_on_control_plane"></a> [allow\_scheduling\_on\_control\_plane](#input\_allow\_scheduling\_on\_control\_plane) | Whether to allow non-control-plane workloads to run on the control-plane nodes | `bool` | `false` | no |
| <a name="input_automatically_upgrade_k3s"></a> [automatically\_upgrade\_k3s](#input\_automatically\_upgrade\_k3s) | Whether to automatically upgrade k3s based on the selected channel | `bool` | `true` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster | `string` | `"k3s"` | no |
| <a name="input_cni_plugin"></a> [cni\_plugin](#input\_cni\_plugin) | CNI plugin for k3s | `string` | `"flannel"` | no |
| <a name="input_control_plane_nodepools"></a> [control\_plane\_nodepools](#input\_control\_plane\_nodepools) | Number of control plane nodes. | `list(any)` | `[]` | no |
| <a name="input_disable_hetzner_csi"></a> [disable\_hetzner\_csi](#input\_disable\_hetzner\_csi) | Disable hetzner csi driver | `bool` | `false` | no |
| <a name="input_disable_network_policy"></a> [disable\_network\_policy](#input\_disable\_network\_policy) | Disable k3s default network policy controller (default false, automatically true for calico) | `bool` | `false` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | Enable cert manager | `bool` | `false` | no |
| <a name="input_enable_longhorn"></a> [enable\_longhorn](#input\_enable\_longhorn) | Enable Longhorn | `bool` | `false` | no |
| <a name="input_enable_rancher"></a> [enable\_rancher](#input\_enable\_rancher) | Enable rancher | `bool` | `false` | no |
| <a name="input_extra_firewall_rules"></a> [extra\_firewall\_rules](#input\_extra\_firewall\_rules) | Additional firewall rules to apply to the cluster | `list(any)` | `[]` | no |
| <a name="input_hcloud_ssh_key_id"></a> [hcloud\_ssh\_key\_id](#input\_hcloud\_ssh\_key\_id) | If passed, a key already registered within hetzner is used. Otherwise, a new one will be created by the module. | `string` | `null` | no |
| <a name="input_hcloud_token"></a> [hcloud\_token](#input\_hcloud\_token) | Hetzner Cloud API Token | `string` | n/a | yes |
| <a name="input_hetzner_ccm_version"></a> [hetzner\_ccm\_version](#input\_hetzner\_ccm\_version) | Version of Kubernetes Cloud Controller Manager for Hetzner Cloud | `string` | `null` | no |
| <a name="input_hetzner_csi_version"></a> [hetzner\_csi\_version](#input\_hetzner\_csi\_version) | Version of Container Storage Interface driver for Hetzner Cloud | `string` | `null` | no |
| <a name="input_initial_k3s_channel"></a> [initial\_k3s\_channel](#input\_initial\_k3s\_channel) | Allows you to specify an initial k3s channel | `string` | `"stable"` | no |
| <a name="input_kured_version"></a> [kured\_version](#input\_kured\_version) | Version of Kured | `string` | `null` | no |
| <a name="input_load_balancer_disable_ipv6"></a> [load\_balancer\_disable\_ipv6](#input\_load\_balancer\_disable\_ipv6) | Disable ipv6 for the load balancer | `bool` | `false` | no |
| <a name="input_load_balancer_location"></a> [load\_balancer\_location](#input\_load\_balancer\_location) | Default load balancer location | `string` | `"fsn1"` | no |
| <a name="input_load_balancer_type"></a> [load\_balancer\_type](#input\_load\_balancer\_type) | Default load balancer server type | `string` | `"cpx11"` | no |
| <a name="input_metrics_server_enabled"></a> [metrics\_server\_enabled](#input\_metrics\_server\_enabled) | Whether to enable or disbale k3s mertric server | `bool` | `true` | no |
| <a name="input_network_region"></a> [network\_region](#input\_network\_region) | Default region for network | `string` | `"eu-central"` | no |
| <a name="input_placement_group_disable"></a> [placement\_group\_disable](#input\_placement\_group\_disable) | Whether to disable placement groups | `bool` | `false` | no |
| <a name="input_rancher_hostname"></a> [rancher\_hostname](#input\_rancher\_hostname) | Enable rancher | `string` | `"rancher.example.com"` | no |
| <a name="input_rancher_install_channel"></a> [rancher\_install\_channel](#input\_rancher\_install\_channel) | Rancher install channel | `string` | `"stable"` | no |
| <a name="input_rancher_registration_manifest_url"></a> [rancher\_registration\_manifest\_url](#input\_rancher\_registration\_manifest\_url) | The url of a rancher registration manifest to apply. (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/) | `string` | `""` | no |
| <a name="input_ssh_additional_public_keys"></a> [ssh\_additional\_public\_keys](#input\_ssh\_additional\_public\_keys) | Additional SSH public Keys. Use them to grant other team members root access to your cluster nodes | `list(string)` | `[]` | no |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | SSH private Key. | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public Key. | `string` | n/a | yes |
| <a name="input_traefik_acme_email"></a> [traefik\_acme\_email](#input\_traefik\_acme\_email) | Email used to recieved expiration notice for certificate | `string` | `false` | no |
| <a name="input_traefik_acme_tls"></a> [traefik\_acme\_tls](#input\_traefik\_acme\_tls) | Whether to include the TLS configuration with the Traefik configuration | `bool` | `false` | no |
| <a name="input_traefik_additional_options"></a> [traefik\_additional\_options](#input\_traefik\_additional\_options) | n/a | `list(string)` | `[]` | no |
| <a name="input_traefik_enabled"></a> [traefik\_enabled](#input\_traefik\_enabled) | Whether to enable or disbale k3s traefik installation | `bool` | `true` | no |
| <a name="input_use_cluster_name_in_node_name"></a> [use\_cluster\_name\_in\_node\_name](#input\_use\_cluster\_name\_in\_node\_name) | Whether to use the cluster name in the node name | `bool` | `true` | no |
| <a name="input_use_klipper_lb"></a> [use\_klipper\_lb](#input\_use\_klipper\_lb) | Use klipper load balancer | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_agents_public_ipv4"></a> [agents\_public\_ipv4](#output\_agents\_public\_ipv4) | The public IPv4 addresses of the agent server. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Shared suffix for all resources belonging to this cluster. |
| <a name="output_control_planes_public_ipv4"></a> [control\_planes\_public\_ipv4](#output\_control\_planes\_public\_ipv4) | The public IPv4 addresses of the controlplane server. |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Structured kubeconfig data to supply to other providers |
| <a name="output_kubeconfig_file"></a> [kubeconfig\_file](#output\_kubeconfig\_file) | Kubeconfig file content with external IP address |
| <a name="output_load_balancer_public_ipv4"></a> [load\_balancer\_public\_ipv4](#output\_load\_balancer\_public\_ipv4) | The public IPv4 address of the Hetzner load balancer |
<!-- END_TF_DOCS -->