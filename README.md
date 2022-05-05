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

### 💡 [Do not skip] Creating the terraform.tfvars file

1. Create a project in your [Hetzner Cloud Console](https://console.hetzner.cloud/), and go to **Security > API Tokens** of that project to grab the API key. Take note of the key! ✅
2. Generate a passphrase-less ed25519 SSH key pair for your cluster; take note of the respective paths of your private and public keys. Or, see our detailed [SSH options](https://github.com/kube-hetzner/kube-hetzner/blob/master/docs/ssh.md). ✅
3. Copy `terraform.tfvars.example` to `terraform.tfvars`, and replace the values from steps 1 and 2. ✅
4. Make sure you have the latest Terraform version, ideally at least 1.1.0. You can check with `terraform -v`. ✅
5. (Optional) Other variables in `terraform.tfvars` can be customized, like the Hetzner region and the node counts and sizes.

_One of the easiest ways to use this project is as a Terraform module; see the [examples](#examples) section or the [Kube-Hetzner Terraform module](https://registry.terraform.io/modules/kube-hetzner/kube-hetzner/hcloud/latest) page._

### 🎯 Installation

```sh
terraform init --upgrade
terraform apply -auto-approve
```

It will take around 5 minutes to complete, and then you should see a green output with the IP addresses of the nodes.

## Usage

When your brand new cluster is up and running, the sky is your limit! 🎉

You can immediately kubectl into it (using the `kubeconfig.yaml` saved to the project's directory after the installation). By doing `kubectl --kubeconfig kubeconfig.yaml`, but for more convenience, either create a symlink from `~/.kube/config` to `kubeconfig.yaml` or add an export statement to your `~/.bashrc` or `~/.zshrc` file, as follows (you can get the path of `kubeconfig.yaml` by running `pwd`):

```sh
export KUBECONFIG=/<path-to>/kubeconfig.yaml
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

Rarely needed, but can be handy in the long run. During the installation, we automatically download a backup of the kustomization to a `kustomization_backup.yaml` file. You will find it next to your `kubeconfig.yaml` at the root of your project.

1. First create a duplicate of that file and name it `kustomization.yaml`, keeping the original file intact, in case you need to restore the old config.
2. Edit the `kustomization.yaml` file; you want to go to the very bottom where you have the links to the different source files; grab the latest versions for each on Github, and replace. If present, remove any local reference to traefik_config.yaml, as Traefik is updated automatically by the system upgrade controller.
3. Apply the the updated `kustomization.yaml` with `kubectl apply -k ./`.

## Examples

<details>

<summary>Ingress with TLS</summary>

Here is an example of an ingress to run an application with TLS, change the host to fit your need in `examples/tls/ingress.yaml` and then deploy the example:

```sh
kubectl apply -f examples/tls/.

```

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: Nginx-ingress
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
                name: nginx-service
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

<summary>Use as Terraform module</summary>

It is easy to use Kube-Hetzner as a Terraform module. To do so:

``` terraform
module "kube-hetzner" {
  source  = "kube-hetzner/kube-hetzner/hcloud"

  # insert the required variables here found in terraform.tfvars.example
}
```

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
