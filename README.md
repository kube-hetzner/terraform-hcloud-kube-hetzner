[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/mysticaltech/kube-hetzner">
    <img src="https://github.com/kube-hetzner/kube-hetzner/raw/master/.images/kube-hetzner-logo.png" alt="Logo" width="112" height="112">
  </a>

  <h2 align="center">Kube-Hetzner</h2>

  <p align="center">
    A highly optimized and auto-upgradable, HA-default & Load-Balanced, Kubernetes cluster powered by k3s-on-MicroOS and deployed for peanuts on <a href="https://hetzner.com" target="_blank">Hetzner Cloud</a> 🤑 🚀
  </p>
  <hr />
</p>

## About The Project

[Hetzner Cloud](https://hetzner.com) is a good cloud provider that offers very affordable prices for cloud instances, with data center locations in both Europe and the US.

This project aims to create an optimal and highly optimized Kubernetes installation that is easily maintained, secure and automatic upgrades. We aimed for functionality as close as possible to GKE's auto-pilot.

To achieve this, we built it on the shoulders of giants by choosing [openSUSE MicroOS](https://en.opensuse.org/Portal:MicroOS) as the base operating system and [k3s](https://k3s.io/) as the Kubernetes engine.

_Please note that we are not affiliates of Hetzner; this is just an open-source project striving to be an optimal solution for deploying and maintaining Kubernetes on Hetzner Cloud._

### Features

- Maintenance-free with auto-upgrade to the latest version of MicroOS and k3s.
- Proper use of the Hetzner private network to minimize latency and remove the need for encryption.
- Automatic HA with the default setting of three control-plane nodes and two agent nodes.
- Super-HA: Nodepools for both control-plane and agent nodes can be in different locations.
- Possibility to have a single node cluster with a proper ingress controller.
- Ability to add nodes and nodepools when the cluster is running.
- Traefik ingress controller attached to a Hetzner load balancer with proxy protocol turned on.
- Possibility to turn Longhorn on, and optionally also turn Hetzner CSI off.
- Ability to switch to Calico as CNI, and Cilium can also be easily added.
- Tons of flexible configuration options to suit all needs.

_It uses Terraform to deploy as it's easy to use, and Hetzner provides a great [Hetzner Terraform Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)._

![Product Name Screen Shot][product-screenshot]

<!-- GETTING STARTED -->

## Getting Started

Follow those simple steps, and your world's cheapest Kube cluster will be up and running.

### ✔️ Prerequisites

First and foremost, you need to have a Hetzner Cloud account. You can sign up for free [here](https://hetzner.com/cloud/).

Then you'll need to have [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli),  [kubectl](https://kubernetes.io/docs/tasks/tools/) cli and [hcloud](<https://github.com/hetznercloud/cli>) the Hetzner cli. The easiest way is to use the [homebrew](https://brew.sh/) package manager to install them (available on Linux, Mac, and Windows Linux Subsystem).

```sh
brew install terraform
brew install kubectl
brew install hcloud

```

### 💡 [Do not skip] Creating your kube.tf file

1. Create a project in your [Hetzner Cloud Console](https://console.hetzner.cloud/), and go to **Security > API Tokens** of that project to grab the API key. Take note of the key! ✅
2. Generate a passphrase-less ed25519 SSH key pair for your cluster; take note of the respective paths of your private and public keys. Or, see our detailed [SSH options](https://github.com/kube-hetzner/kube-hetzner/blob/master/docs/ssh.md). ✅
3. Prepare the module by copying `kube.tf.example` to `kube.tf` **in a new folder** which you cd into, then replace the values from steps 1 and 2. ✅
4. (Optional) Many variables in `kube.tf` can be customized to suit your needs, you can do so if you want. ✅
5. Make sure you have the latest Terraform version, at least 1.2.0. You can check with `terraform -v`. ✅
6. At this stage you should be in your new folder, with a fresh `kube.tf` file, if it is so, you can proceed forward! ✅

_It's important to realize that you do not even need to clone this git repo, as the module by default will be fetched from the Terraform registry. All you need, is to use the [kube.tf.example](https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/kube.tf.example) file to make sure you get the format of your `kube.tf` file right._

_A complete reference of all inputs, outputs, modules etc. can be found in the [terraform.md](https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/docs/terraform.md) file._

### 🎯 Installation

```sh
terraform init --upgrade
terraform apply -auto-approve
```

It will take around 5 minutes to complete, and then you should see a green output with the IP addresses of the nodes.

## Usage

When your brand new cluster is up and running, the sky is your limit! 🎉

You can immediately kubectl into it (using the `${cluster_name}_kubeconfig.yaml` saved to the project's directory after the installation). By doing `kubectl --kubeconfig ${cluster_name}_kubeconfig.yaml`, but for more convenience, either create a symlink from `~/.kube/config` to `${cluster_name}_kubeconfig.yaml` or add an export statement to your `~/.bashrc` or `~/.zshrc` file, as follows (you can get the path of `${cluster_name}_kubeconfig.yaml` by running `pwd`):

```sh
export KUBECONFIG=/<path-to>/${cluster_name}_kubeconfig.yaml
```

_Once you start with Terraform, it's best not to change the state manually in Hetzner; otherwise, you'll get an error when you try to scale up or down or even destroy the cluster._

### Scaling Nodes

Two things can be scaled: the number of nodepools or the number of nodes in these nodepools. You have two lists of nodepools you can add to in `terraform.tfvars`, the control plane nodepool and the agent nodepool list. Combined, they cannot exceed 255 nodepools (you are extremely unlikely to reach this limit). As for the count of nodes per nodepools, if you raise your limits in Hetzner, you can have up to 64,670 nodes per nodepool (also very unlikely to need that much).

There are some limitations (to scaling down mainly) that you need to be aware of:

_Once the cluster is up; you can change any nodepool count and even set it to 0 (in the case of the first control-plane nodepool, the minimum is 1); you can also rename a nodepool (if the count is to 0), but should not remove a nodepool from the list after once the cluster is up. That is due to how subnets and IPs get allocated. The only nodepools you can remove are those at the end of each list of nodepools._

_However, you can freely add other nodepools at the end of the list, increasing the node count. You can also decrease the node count, but make sure you drain the node in question before; otherwise, it will leave your cluster in a bad state. For obvious reasons, the only nodepool that needs at least to have a count of 1 always is the first control-plane nodepool._

## High Availability

By default, we have three control planes and three agents configured, with automatic upgrades and reboots of the nodes.

If you want to remain HA (no downtime), it's essential to **keep a count of control planes nodes of at least three** (two minimum to maintain quorum when one goes down for automated upgrades and reboot), see [Rancher's doc on HA](https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/).

Otherwise, it's essential to turn off automatic OS upgrades (k3s can continue to update without issue) for the control-plane nodes (when two or fewer control-plane nodes) and do the maintenance yourself.

## Automatic Upgrade

### The Default Setting

By default, MicroOS gets upgraded automatically on each node and reboot safely via [Kured](https://github.com/weaveworks/kured) installed in the cluster.

As for k3s, it also automatically upgrades thanks to Rancher's [system upgrade controller](https://github.com/rancher/system-upgrade-controller). By default, it follows the k3s `stable` channel, but you can also change to the `latest` one if needed or specify a target version to upgrade to via the upgrade plan.

You can copy and modify the [one in the templates](https://github.com/kube-hetzner/kube-hetzner/blob/master/templates/plans.yaml.tpl) for that! More on the subject in [k3s upgrades](https://rancher.com/docs/k3s/latest/en/upgrades/basic/).

### Turning Off Automatic Upgrade

_If you wish to turn off automatic MicroOS upgrades (Important if you are not launching an HA setup which requires at least 3 control-plane nodes), you need to ssh into each node and issue the following command:_

```sh
systemctl --now disable transactional-update.timer

```

_To turn off k3s upgrades, you can either remove the `k3s_upgrade=true` label or set it to `false`. This needs to happen for all the nodes too! To remove it, apply:_

```sh
kubectl -n system-upgrade label node <node-name> k3s_upgrade-
```

Alternatively, you can disable the k3s automatic upgrade without individually editing the labels on the nodes. Instead you can just delete the two system controller upgrade plans with:

```sh
kubectl delete plan k3s-agent -n system-upgrade
kubectl delete plan k3s-server -n system-upgrade
```

### Individual Components Upgrade

Rarely needed, but can be handy in the long run. During the installation, we automatically download a backup of the kustomization to a `kustomization_backup.yaml` file. You will find it next to your `${cluster_name}_kubeconfig.yaml` at the root of your project.

1. First create a duplicate of that file and name it `kustomization.yaml`, keeping the original file intact, in case you need to restore the old config.
2. Edit the `kustomization.yaml` file; you want to go to the very bottom where you have the links to the different source files; grab the latest versions for each on Github, and replace. If present, remove any local reference to traefik_config.yaml, as Traefik is updated automatically by the system upgrade controller.
3. Apply the the updated `kustomization.yaml` with `kubectl apply -k ./`.

## Examples

<details>

<summary>Ingress with TLS</summary>

You have two solutions, the first is to use `Cert-Manager` to take care of the certificates, and the second is to let `Traefik` bear this responsability.

_We advise you to use the first one, as it supports HA setups without requiring you to use the enterprise version of Traefik. The reason for that is that according to Traefik themselves, Traefik CE (community edition) is stateless, and it's not possible to run multiple instance of Traefik CE with LetsEncrypt enabled. Meaning, you cannot have your ingress be HA with Traefik if you use the community edition and have activated the LetsEncrypt resolver. You could however use Traefik EE (enterprise edition) to achieve that. Long story short, if you are going to use Traefik CE (like most of us), you should use cert-manager to generate the certificates. Source [here](https://doc.traefik.io/traefik/v2.0/providers/kubernetes-crd/)._

### Via Cert-Manager (recommended)

In your module variables, set `enable_cert_manager` to `true`, and just create your issuers as decribed here <https://cert-manager.io/docs/configuration/acme/>.

Then in your Ingress definition, just mentioning the issuer as an annotation and giving a secret name will take care of instructing cert-manager to generate a certificate for it! It simpler than the alternative, you just have to configure your issuer(s) first with the method of your choice.

Ingress example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  tls:
  - hosts:
    - '*.example.com'
    secretName: example-com-letsencrypt-tls
  rules:
  - host: '*.example.com'
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

### Via Traefik CE (not recommended)

Here is an example of an ingress to run an application with TLS, change the host to fit your need in `examples/tls/ingress.yaml` and then deploy the example:

```sh
kubectl apply -f examples/tls/.

```

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.tls.certresolver: le
spec:
  tls:
    - hosts:
        - example.com
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80

```

</details>

<details>

<summary>Single-node cluster</summary>

Running a development cluster on a single node without any high availability is also possible. You need one control plane nodepool with a count of 1 and one agent nodepool with a count of 0.

In this case, we don't deploy an external load-balancer but use the default [k3s service load balancer](https://rancher.com/docs/k3s/latest/en/networking/#service-load-balancer) on the host itself and open up port 80 & 443 in the firewall (done automatically).

</details>

<details>

<summary>Use in Terraform cloud</summary>

To use Kube-Hetzner on Terraform cloud, use as a Terraform module as mentioned above, but also change the execution mode from `remote` to `local`.

</details>

<details>

<summary>Configure add-ons with HelmChartConfig</summary>

For instance, to customize the Rancher install, if you choose to enable it, you can create and apply the following `HelmChartConfig`:

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rancher
  namespace: kube-system
spec:
  valuesContent: |-
    **values.yaml content you want to customize**
```

The helm options for Rancher can be seen here <https://github.com/rancher/rancher/blob/release/v2.6/chart/values.yaml>.

Same goes for all add-ons, like Longhorn, Cert-manager, and Traefik.

</details>

## Debugging

First and foremost, it depends, but it's always good to have a quick look into Hetzner quickly without logging in to the UI. That is where the `hcloud` cli comes in.

- Activate it with `hcloud context create Kube-hetzner`; it will prompt for your Hetzner API token, paste that, and hit `enter`.
- To check the nodes, if they are running, use `hcloud server list`.
- To check the network, use `hcloud network describe k3s`.
- To look at the LB, use `hcloud loadbalancer describe traefik`.

Then for the rest, you'll often need to login to your cluster via ssh, to do that, use:

```sh
ssh root@xxx.xxx.xxx.xxx -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no

```

Then, for control-plane nodes, use `journalctl -u k3s` to see the k3s logs, and for agents, use `journalctl -u k3s-agent` instead.

Last but not least, to see when the previous reboot took place, you can use both `last reboot` and `uptime`.

## Takedown

If you want to take down the cluster, you can proceed as follows:

```sh
terraform destroy -auto-approve
```

And if the network is slow to delete, just issue `hcloud network delete k3s` to speed things up!

_Also, if you had a full-blown cluster in use, it would be best to delete the whole project in your Hetzner account directly as operators or deployments may create other resources during regular operation._

<!-- CONTRIBUTING -->

## History

This project has tried two other OS flavors before settling on MicroOS. Fedora Server, and k3OS. The latter, k3OS, is now defunct! However, our code base for it lives on in the [k3os branch](https://github.com/kube-hetzner/kube-hetzner/tree/k3os). Do not hesitate to check it out, it should still work.

There is also a branch where openSUSE MicroOS came preinstalled with the k3s RPM from devel:kubic/k3s, but we moved away from that solution as the k3s version was rarely getting updates. See the [microOS-k3s-rpm](https://github.com/kube-hetzner/kube-hetzner/tree/microOS-k3s-rpm) branch for more.

## Contributing

🌱 This project currently installs openSUSE MicroOS via the Hetzner rescue mode, making things a few minutes slower. If you could **take a few minutes to send a support request to Hetzner, asking them to please add openSUSE MicroOS as a default image**, not just an ISO. The more requests they receive, the likelier they are to add support for it, and if they do, that will cut the deployment time by half. The official link to openSUSE MicroOS is <https://get.opensuse.org/microos>, and their `OpenStack Cloud` image has full support for Cloud-init, which would probably suit the Hetzner Ops team!

Code contributions are very much **welcome**.

1. Fork the Project
2. Create your Branch (`git checkout -b AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature")
4. Push to the Branch (`git push origin AmazingFeature`)
5. Open a Pull Request targetting the `staging` branch.

<!-- ACKNOWLEDGEMENTS -->

## Acknowledgements

- [k-andy](https://github.com/StarpTech/k-andy) was the starting point for this project. It wouldn't have been possible without it.
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template) made writing this readme a lot easier.
- [Hetzner Cloud](https://www.hetzner.com) for providing a solid infrastructure and terraform package.
- [Hashicorp](https://www.hashicorp.com) for the amazing terraform framework that makes all the magic happen.
- [Rancher](https://www.rancher.com) for k3s, an amazing Kube distribution that is the core engine of this project.
- [openSUSE](https://www.opensuse.org) for MicroOS, which is just next level Container OS technology.

[contributors-shield]: https://img.shields.io/github/contributors/mysticaltech/kube-hetzner.svg?style=for-the-badge
[contributors-url]: https://github.com/mysticaltech/kube-hetzner/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/mysticaltech/kube-hetzner.svg?style=for-the-badge
[forks-url]: https://github.com/mysticaltech/kube-hetzner/network/members
[stars-shield]: https://img.shields.io/github/stars/mysticaltech/kube-hetzner.svg?style=for-the-badge
[stars-url]: https://github.com/mysticaltech/kube-hetzner/stargazers
[issues-shield]: https://img.shields.io/github/issues/mysticaltech/kube-hetzner.svg?style=for-the-badge
[issues-url]: https://github.com/mysticaltech/kube-hetzner/issues
[license-shield]: https://img.shields.io/github/license/mysticaltech/kube-hetzner.svg?style=for-the-badge
[license-url]: https://github.com/mysticaltech/kube-hetzner/blob/master/LICENSE.txt
[product-screenshot]: https://github.com/kube-hetzner/kube-hetzner/raw/master/.images/kubectl-pod-all-17022022.png

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