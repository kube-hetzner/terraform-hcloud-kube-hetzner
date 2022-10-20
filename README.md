[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/mysticaltech/kube-hetzner">
    <img src="https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/raw/master/.images/kube-hetzner-logo.png" alt="Logo" width="112" height="112">
  </a>

  <h2 align="center">Kube-Hetzner</h2>

  <p align="center">
    A highly optimized, easy-to-use, auto-upgradable, HA-default & Load-Balanced, Kubernetes cluster powered by k3s-on-MicroOS and deployed for peanuts on <a href="https://hetzner.com" target="_blank">Hetzner Cloud</a> 🤑 🚀
  </p>
  <hr />
</p>

## About The Project

[Hetzner Cloud](https://hetzner.com) is a good cloud provider that offers very affordable prices for cloud instances, with data center locations in both Europe and the US.

This project aims to create a highly optimized Kubernetes installation that is easy to maintain, secure and automatically upgrades both the nodes and Kubernetes. We aimed for functionality as close as possible to GKE's Auto-Pilot.

To achieve this, we built it on the shoulders of giants by choosing [openSUSE MicroOS](https://en.opensuse.org/Portal:MicroOS) as the base operating system and [k3s](https://k3s.io/) as the k8s engine.

_Please note that we are not affiliates of Hetzner; this is just an open-source project striving to be an optimal solution for deploying and maintaining Kubernetes on Hetzner Cloud._

### Features

- Maintenance-free with auto-upgrades to the latest version of MicroOS and k3s.
- Proper use of the Hetzner private network to minimize latency and remove the need for encryption.
- Traefik or Nginx as ingress controller attached to a Hetzner load balancer with Proxy Protocol turned on.
- Automatic HA with the default setting of three control-plane nodes and two agent nodes.
- Super-HA: Nodepools for both control-plane and agent nodes can be in different locations.
- Possibility to have a single node cluster with a proper ingress controller.
- Can use Klipper as an "on-metal" LB instead of the Hetzner LB.
- Ability to add nodes and nodepools when the cluster is running.
- Possibility to turn Longhorn (using either Hetzner volumes or node storage), and/or Hetzner CSI.
- Choose between Flannel (default), Calico, or Cilium as CNI.
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
2. Generate a passphrase-less ed25519 SSH key pair for your cluster; take note of the respective paths of your private and public keys. Or, see our detailed [SSH options](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/blob/master/docs/ssh.md). ✅
3. Prepare the module by copying `kube.tf.example` to `kube.tf` **in a new folder** which you cd into, then replace the values from steps 1 and 2. ✅
4. (Optional) Many variables in `kube.tf` can be customized to suit your needs, you can do so if you want. ✅
5. At this stage you should be in your new folder, with a fresh `kube.tf` file, if it is so, you can proceed forward! ✅

_A complete reference of all inputs, outputs, modules etc. can be found in the [terraform.md](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/blob/master/docs/terraform.md) file._

_It's important to realize that your kube.tf needs to reside in a NEW folder, not a clone of this git repo (the module by default will be fetched from the Terraform registry). All you need, is to re-use the [kube.tf.example](https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/kube.tf.example) file to make sure you get the format right._

### 🎯 Installation

```sh
terraform init --upgrade
terraform validate
terraform apply -auto-approve
```

It will take around 5 minutes to complete, and then you should see a green output confirming a successful deployment.

## Usage

When your brand new cluster is up and running, the sky is your limit! 🎉

You can immediately kubectl into it (by exporting the kubeconfig to a file via `terraform output --raw kubeconfig > clustername_kubeconfig.yaml` after the installation). By doing `kubectl --kubeconfig clustername_kubeconfig.yaml`, but for more convenience, either create a symlink from `~/.kube/config` to `clustername_kubeconfig.yaml` or add an export statement to your `~/.bashrc` or `~/.zshrc` file, as follows (you can get the path of `clustername_kubeconfig.yaml` by running `pwd`):

```sh
export KUBECONFIG=/<path-to>/clustername_kubeconfig.yaml
```

_Once you start with Terraform, it's best not to change the state manually in Hetzner; otherwise, you'll get an error when you try to scale up or down or even destroy the cluster._

## CNI

The default is Flannel, but you can also choose Calico or Cilium, by setting the `cni_plugin` variable in `kube.tf` to "calico" or "cilium".

As Cilium has a lot of interesting and powerful configurations possibility. We give you the possibiliy to add a `cilium_values.yaml` file to the root of your module before you deploy your cluster, the same place where you have your `kube.tf` file. This file must be of the same format as the Cilium [values.yaml file](https://github.com/cilium/cilium/blob/master/install/kubernetes/cilium/values.yaml), but with the values you want to modify. During the deploy, Terraform will test to see if this file is present and if so will use those values to deploy the Cilium Helm chart.

### Scaling Nodes

Two things can be scaled: the number of nodepools or the number of nodes in these nodepools. You have two lists of nodepools you can add to your `kube.tf`, the control plane nodepool and the agent nodepool list. Combined, they cannot exceed 255 nodepools (you are extremely unlikely to reach this limit). As for the count of nodes per nodepools, if you raise your limits in Hetzner, you can have up to 64,670 nodes per nodepool (also very unlikely to need that much).

There are some limitations (to scaling down mainly) that you need to be aware of:

_Once the cluster is up; you can change any nodepool count and even set it to 0 (in the case of the first control-plane nodepool, the minimum is 1); you can also rename a nodepool (if the count is to 0), but should not remove a nodepool from the list after once the cluster is up. That is due to how subnets and IPs get allocated. The only nodepools you can remove are those at the end of each list of nodepools._

_However, you can freely add other nodepools at the end of each list. And for each nodepools, you can freely increase or decrease the node count (if you want to decrease a nodepool node count make sure you drain the nodes in question before, you can use `terraform show` to identify the node names at the end of the nodepool list, otherwise, if you do not drain the nodes before removing them, it could leave your cluster in a bad state). The only nodepool that needs to have always at least a count of 1 is the first control-plane nodepool._

## High Availability

By default, we have three control planes and three agents configured, with automatic upgrades and reboots of the nodes.

If you want to remain HA (no downtime), it's essential to **keep a count of control planes nodes of at least three** (two minimum to maintain quorum when one goes down for automated upgrades and reboot), see [Rancher's doc on HA](https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/).

Otherwise, it is essential to turn off automatic OS upgrades (k3s can continue to update without issue) for the control-plane nodes (when two or fewer control-plane nodes) and do the maintenance yourself.

## Automatic Upgrade

### The Default Setting

By default, MicroOS gets upgraded automatically on each node and reboot safely via [Kured](https://github.com/weaveworks/kured) installed in the cluster.

As for k3s, it also automatically upgrades thanks to Rancher's [system upgrade controller](https://github.com/rancher/system-upgrade-controller). By default, it follows the k3s `stable` channel, but you can also change to the `latest` one if needed or specify a target version to upgrade to via the upgrade plan.

You can copy and modify the [one in the templates](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/blob/master/templates/plans.yaml.tpl) for that! More on the subject in [k3s upgrades](https://rancher.com/docs/k3s/latest/en/upgrades/basic/).

### Turning Off Automatic Upgrade

_If you wish to turn off automatic MicroOS upgrades (Important if you are not launching an HA setup which requires at least 3 control-plane nodes), you need to set:_ 
```terraform
automatically_upgrade_os = false
```

_Alternatively ssh into each node and issue the following command:_

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

Rarely needed, but can be handy in the long run. During the installation, we automatically download a backup of the kustomization to a `kustomization_backup.yaml` file. You will find it next to your `clustername_kubeconfig.yaml` at the root of your project.

1. First create a duplicate of that file and name it `kustomization.yaml`, keeping the original file intact, in case you need to restore the old config.
2. Edit the `kustomization.yaml` file; you want to go to the very bottom where you have the links to the different source files; grab the latest versions for each on Github, and replace. If present, remove any local reference to traefik_config.yaml, as Traefik is updated automatically by the system upgrade controller.
3. Apply the the updated `kustomization.yaml` with `kubectl apply -k ./`.

## Customizing the Cluster Components

Most cluster components of Kube-Hetzner are deployed with the Rancher [Helm Chart](https://rancher.com/docs/k3s/latest/en/helm/) yaml definition and managed by the Helm Controller inside of k3s.

By default, we strive to give you optimal defaults, but if you with to customize them, you can do so.

### Before deploying

In the case of Traefik, Rancher, and Longhorn, we provide you with variables to configure everything you need.

On top of the above, for Nginx, Rancher, Cilium and Longhorn, for maximum flexibility, we give you the ability to add a Helm values.yaml file (for instance, `cilium_values.yaml`) to the root of your module, the same place where you have your `kube.tf` file. _You can find a `_values.yaml.example` value file for each listed component at the root of this project._

### After deploying

Once the Cluster is up and running, you can easily customize many components like Traefik, Nginx, Rancher, Cilium, Cert-Manager and Longhorn by using HelmChartConfig definitions. See the [examples](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner#examples) section, for more information.

For other components like Calico and Kured (which uses manifests), we automatically save a `kustomization_backup.yaml` file in the root of your module during the deploy, so you can use that as a starting point. This is also useful when creating the HelmChartConfig definitions, as both HelmChart and HelmChartConfig definitions are very similar.

## Adding Extras

If you need to install additional Helm charts or Kubernetes manifests that are not provided by default, you can easily do so by using [Kustomize](https://kustomize.io). This is done by creating the `extra-manifests/kustomization.yaml.tpl` directory besides your `kube.tf`. 

This file needs to be a valid `Kustomization` manifest, but it supports terraform templating! (The templating parameters can be passed via the `extra_kustomize_parameters` variable to the module).

All files in the `extra-manifests` directory including the rendered version of `kustomization.yaml.tpl` will be applied to k3s with `kubectl apply -k` (which will be executed after and independently of the basic cluster configuration).

_You can use the above to pass all kinds of kubenertes YAML configs, including HelmChart and/or HelmChartConfig definitions (see the previous section if you do not know what those are in the context of k3s)._

## Examples

<details>
  
<summary>Useful Cilium commands</summary>

With Kube-Hetzner, you have the possibility to use Cilium as a CNI. It's very powerful and has great observability features. Below you will find a few useful commands.

- Check the status of cilium with the following commands (get the cilium pod name first and replace it in the command):

```sh
kubectl -n kube-system exec --stdin --tty cilium-xxxx -- cilium status
kubectl -n kube-system exec --stdin --tty cilium-xxxx -- cilium status --verbose
```

- Monitor cluster traffic with:

```sh
kubectl -n kube-system exec --stdin --tty cilium-xxxx -- cilium monitor
```

- See the list of kube services with:

```sh
kubectl -n kube-system exec --stdin --tty cilium-xxxx -- cilium service list
```

_For more cilium commands, please refer to their corresponding [Documentation](https://docs.cilium.io/en/latest/cheatsheet)._
  
</details>

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
  
_⚠️ In case of using Ingress-Nginx as ingress controller, if you choose to use the HTTP challenge method you need to do an additional step of adding this annotation `load-balancer.hetzner.cloud/hostname` to the Nginx service definition. And you set it equal to a FQDN that points to your LB address. 
  
This is to circumvent this known issue https://github.com/cert-manager/cert-manager/issues/466, also see https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/issues/354. Otherwise, you can just use the DNS challenge, which does not require any additional tweaks to work._

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

Running a development cluster on a single node without any high availability is also possible.

When doing so, `automatically_upgrade_os` should be set to `false`, especially with attached volumes the automatic reboots won't work properly.
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

And if the network is slow to delete, just issue `hcloud load-balancer delete clustername` to speed things up! As the load-balancer is usually the ressoure that is the slowest to get deleted on its own.

_Also, if you had a full-blown cluster in use, it would be best to delete the whole project in your Hetzner account directly as operators or deployments may create other resources during regular operation._

<!-- CONTRIBUTING -->

## History

This project has tried two other OS flavors before settling on MicroOS. Fedora Server, and k3OS. The latter, k3OS, is now defunct! However, our code base for it lives on in the [k3os branch](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/tree/k3os). Do not hesitate to check it out, it should still work.

There is also a branch where openSUSE MicroOS came preinstalled with the k3s RPM from devel:kubic/k3s, but we moved away from that solution as the k3s version was rarely getting updates. See the [microOS-k3s-rpm](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/tree/microOS-k3s-rpm) branch for more.

## Contributing

🌱 This project currently installs openSUSE MicroOS via the Hetzner rescue mode, making things a few minutes slower. To help with that, you could **take a few minutes to send a support request to Hetzner, asking them to please add openSUSE MicroOS as a default image**, not just an ISO. The more requests they receive, the likelier they are to add support for it, and if they do, that will cut the deployment time by half. The official link to openSUSE MicroOS is <https://get.opensuse.org/microos>, and their `OpenStack Cloud` image has full support for Cloud-init, which would probably very much suit the Hetzner Ops team!

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
[product-screenshot]: https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner/raw/master/.images/kubectl-pod-all-17022022.png
