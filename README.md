[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/mysticaltech/kube-hetzner">
    <img src=".images/kube-hetzner-logo.png" alt="Logo" width="112" height="112">
  </a>

  <h2 align="center">Kube-Hetzner</h2>

  <p align="center">
    A highly optimized and auto-upgradable, HA-able & Load-Balanced, Kubernetes cluster powered by k3s-on-MicroOS and deployed for peanuts on <a href="https://hetzner.com" target="_blank">Hetzner Cloud</a> 🤑 🚀
  </p>
  <hr />
  <br />
</p>

## About The Project

[Hetzner Cloud](https://hetzner.com) is a good cloud provider that offers very affordable prices for cloud instances, with data center locations in both Europe and the US.

The goal of this project is to create an optimal and highly optimized Kubernetes installation that is easily maintained, secure, and automatically upgrades. We aimed for functionality as close as possible to GKE's auto-pilot. In order to achieve this, we built it on the shoulders of giants, by choosing [openSUSE MicroOS](https://en.opensuse.org/Portal:MicroOS) as the base operating system, and [k3s](https://k3s.io/) as the Kubernetes engine.

_Please note that we are not affiliated to Hetzner, this is just an open source project striving to be an optimal solution for deploying and maintaining Kubernetes on Hetzner Cloud._

### Features

- Maintenance free with auto-upgrade to the latest version of MicroOS and k3s.
- Proper use of the underlying Hetzner private network to remove the need for encryption and make the cluster both fast and secure.
- Automatic HA with the default setting of three control-plane and two agents nodes.
- Ability to add or remove as many nodes as you want while the cluster stays running.
- Automatic Traefik ingress controller attached to a Hetzner load balancer with proxy protocol turned on.
- (Optional) Out of the box config of Traefik with SSL certficate auto-generation.

_It uses Terraform to deploy as it's easy to use, and Hetzner provides a great [Hetzner Terraform Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)._

![Product Name Screen Shot][product-screenshot]

<!-- GETTING STARTED -->

## Getting started

Follow those simple steps, and your world's cheapest Kube cluster will be up and running in no time.

### ✔️ Prerequisites

First and foremost, you need to have a Hetzner Cloud account. You can sign up for free [here](https://hetzner.com/cloud/).

Then you'll need to have [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) and [kubectl](https://kubernetes.io/docs/tasks/tools/) cli installed. The easiest way is to use the [gofish](https://gofi.sh/#install) package manager to install them.

```sh
gofish install terraform
gofish install kubectl
```

_The Hetzner cli `hcloud` is also useful to have, mainly for debugging without having to use the Hetzner website. See how to install it [here](https://github.com/hetznercloud/cli)._

### 💡 [Do not skip] Creating the terraform.tfvars file

1. Create a project in your [Hetzner Cloud Console](https://console.hetzner.cloud/), and go to **Security > API Tokens** of that project to grab the API key. Take note of the key! ✅
2. Either, generate a passphrase-less ed25519 SSH key-pair for your cluster, unless you already have one that you'd like to use. Take note of the respective paths of your private and public keys. Or, for a key-pair with passphrase or a device like a Yubikey, make sure you have have an SSH agent running and your key is loaded (`ssh-add -L` to verify) and set `private_key = null` in the following step. ✅
3. Copy `terraform.tfvars.example` to `terraform.tfvars`, and replace the values from steps 1 and 2. ✅
4. (Optional) There are other variables in `terraform.tfvars` that could be customized, like Hetzner region, and the node counts and sizes.

### 🎯 Installation

```sh
terraform init
terraform apply -auto-approve
```

It will take around 12 minutes to complete, and then you should see a green output with the IP addresses of the nodes. Then you can immediately kubectl into it (using the kubeconfig.yaml saved to the project's directory after the install).

_Just using the command `kubectl --kubeconfig kubeconfig.yaml` would work, but for more convenience, either create a symlink from `~/.kube/config` to `kubeconfig.yaml`, or add an export statement to your `~/.bashrc` or `~/.zshrc` file, as follows (you can get the path of kubeconfig.yaml by running `pwd`):_

```sh
export KUBECONFIG=/<path-to>/kubeconfig.yaml
```

<!-- USAGE EXAMPLES -->

## Usage

When the cluster is up and running, you can do whatever you wish with it! 🎉

### Scaling nodes

You can scale the number of nodes up and down without any issues. If you are going to scale down, just make sure to properly `kubectl drain` the nodes in question first. Then just edit these variables in `terraform.tfvars` and re-apply terraform with `terraform apply -auto-approve`.

**If you want to be HA, it's important to keep a number of control planes nodes of at least 3 (2 to maintain quorum when 1 goes down for automated upgrades and reboot for instance), see [Rancher's doc on HA](https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/).**

Otherwise, it's important to turn off automatic updates and reboots for the control-plane nodes (2 or less), and do the maintenance yourself.

For instance:

```tfvars
servers_num = 3
agents_num = 2
```

### Useful commands

- List your nodes IPs, with either of those:

```sh
terraform outputs
hcloud server list
```

- See the Hetzner network config:

```sh
hcloud network describe k3s
```

- Log into one of your nodes (replace the location of your private key if needed):

```sh
ssh root@xxx.xxx.xxx.xxx -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no
```

## Automatic upgrade

By default, MicroOS and its embedded k3s instance get upgraded automatically on each node, and reboot safely via [Kured](https://github.com/weaveworks/kured) installed in the cluster.

_You can also choose to automatically kustomize the Hetzner CCM and CSI to set their container images to "latest" with an imagePullPolicy of "Always". That means that when the nodes upgrade, these container images will be automatically upgraded too. For more info on this, see [terraform.tfvars.example](terraform.tfvars.example)._

_About [Kured](https://github.com/weaveworks/kured), it does not have a latest tag present for its image, but it's pretty compatible, so you can just manually update the tag from once every year for instance._

_Last but not least, if you wish to turn off automatic upgrade on a specific node, you need to ssh into it and issue the following command:_

```sh
systemctl --now disable transactional-update.timer
```

## Takedown

If you want to takedown the cluster, you can proceed as follows:

```sh
kubectl delete -k hetzner/csi
kubectl delete -k hetzner/ccm
hcloud load-balancer delete traefik
hcloud network delete k3s
terraform destroy -auto-approve
```

_Also, if you had a full-blown cluster in use, it would be best to delete the whole project in your Hetzner account directly as operators or deployments may create other resources during regular operation._

<!-- CONTRIBUTING -->

## Contributing

Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Branch (`git checkout -b AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin AmazingFeature`)
5. Open a Pull Request

<!-- ACKNOWLEDGEMENTS -->

## Acknowledgements

- [k-andy](https://github.com/StarpTech/k-andy) was the starting point for this project. It wouldn't have been possible without it.
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template) that made writing this readme a lot easier.
- [Hetzner Cloud](https://www.hetzner.com) for providing a solid infrastructure and terraform package.
- [Hashicorp](https://www.hashicorp.com) for the amazing terraform framework that makes all the magic happen.
- [Rancher](https://www.rancher.com) for k3s, an amazing Kube distribution that is the very core engine of this project.
- [openSUSE](https://www.opensuse.org) for MicroOS, which is just next level Container OS technology.
- [k3os](https://github.com/rancher/k3os) really spread its wing with k3os, it's was an amazing OS for k3s. If curious look at our [k3os branch](https://github.com/kube-hetzner/kube-hetzner/tree/k3os).

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
[product-screenshot]: .images/kubectl-pod-all.png