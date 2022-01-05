[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/mysticaltech/kube-hetzner">
    <img src=".images/kube-hetzner-logo.png" alt="Logo" width="112" height="112">
  </a>

  <h2 align="center">Kube-Hetzner</h2>

  <p align="center">
    A highly optimized and auto-upgradable, HA-able, Kubernetes cluster powered by k3s on k3os on <a href="https://hetzner.com" target="_blank">Hetzner Cloud</a> 🤑 
  </p>
  <hr />
  <br />
</p>

## About The Project

[Hetzner Cloud](https://hetzner.com) is a good cloud provider that offers very affordable prices for cloud instances, with data center locations in both Europe and America. The goal of this project was to create an optimal and highly optimized Kubernetes installation that is easily maintained, secure, and automatically upgrades itself. We aimed for functionality as close as possible to GKE's auto-pilot!

_Please note that we are not affiliated to Hetzner, this is just an open source project striving to be an optimal solution for deploying and maintaining Kubernetes on Hetzner Cloud._

### Features

- Lightweight and resource-efficient Kubernetes powered by [k3s](https://github.com/k3s-io/k3s) on [k3os](https://github.com/rancher/k3os) nodes.
- Automatic HA with the default setting of two control-plane and agents nodes.
- Add or remove as many nodes as you want while the cluster stays running (just change the number instances and run terraform apply again).
- Automatic Traefik ingress controller and with a hetzner load balancer and proxy protocol turned on.

_It uses Terraform to deploy as it's easy to use, and Hetzner provides a great [Hetzner Terraform Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)._

![Product Name Screen Shot][product-screenshot]

<!-- GETTING STARTED -->

## Getting started

Follow those simple steps, and your world's cheapest Kube cluster will be up and running in no time.

### Prerequisites

First and foremost, you need to have a Hetzner Cloud account. You can sign up for free [here](https://hetzner.com/cloud/).

Then you'll need you have the [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli), [helm](https://helm.sh/docs/intro/install/), and [kubectl](https://kubernetes.io/docs/tasks/tools/) cli installed. The easiest way is to use the [gofish](https://gofi.sh/#install) package manager to install them.

```sh
gofish install terraform && gofish install kubectl && gofish install helm
```

### Creating terraform.tfvars

1. Create a project in your Hetzner Cloud Console, and go to **Security > API Tokens** of that project to grab the API key.
2. Generate an ssh key pair for your cluster, unless you already have one that you'd like to use.
3. Rename terraform.tfvars.example to terraform.tfvars, and replace the values from steps 1 and 2.

### Customize other variables (Optional)

The number of control plane nodes and worker nodes, the [Hetzner datacenter location](https://docs.hetzner.com/general/others/data-centers-and-connection/) (.i.e. ngb1, fsn1, hel1 ...etc.), and the [Hetzner server types](https://www.hetzner.com/cloud) (i.e. cpx31, cpx41 ...etc.) can be customized by adding the corresponding variables to your newly created terraform.tfvars file.

See the default values in the [variables.tf](variables.tf) file, they correspond to (you can copy-paste and customize):

```tfvars
servers_num = 2
agents_num = 2
location = "fsn1"
agent_server_type = "cpx21"
control_plane_server_type = "cpx11"
lb_server_type = "lb11"
```

### Installation

```sh
terraform init
terraform apply -auto-approve
```

It will take a few minutes to complete, and then you should see a green output with the IP addresses of the nodes. Then you can immediately kubectl into it (using the kubeconfig.yaml saved to the project's directory after the install).

Just using the command `kubectl --kubeconfig kubeconfig.yaml` would work, but for more convenience, either create a symlink from `~/.kube/config` to `kubeconfig.yaml`, or add an export statement to your `~/.bashrc` or `~/.zshrc` file, as follows:

```sh
export KUBECONFIG=/<path-to>/kubeconfig.yaml
```

Of course, to get the path, you could use the `pwd` command.

### Scaling Nodes

You can scale the number of nodes up and down without any issues or even disruption! Just add or edit these variables in `terraform.tfvars` and re-apply terraform.

```tfvars
servers_num = 2
agents_num = 3
```

<!-- USAGE EXAMPLES -->

## Usage

When the cluster is up and running, you can do whatever you wish with it. Enjoy! 🎉

### Useful commands

- List your nodes IPs, with either of those:

```sh
terraform outputs
hcloud server list
```

- See the Hetzner network config:

```sh
hcloud network describe k3s-net
```

- Log into one of your nodes (replace the location of your private key if needed):

```sh
ssh rancher@xxx.xxx.xxx.xxx -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no
```

### Automatic upgrade

By default, k3os and its embedded k3s instance get upgraded automatically on each node, thanks to its embedded system upgrade controller. If you wish to turn that feature off, please remove the following label `k3os.io/upgrade=latest` with the following command:

```sh
kubectl label node <nodename> 'k3os.io/upgrade'- --kubeconfig kubeconfig.yaml
```

As for the Hetzner CCM and CSI, their container images are set to latest and with and imagePullPolicy of "Always". This means that when the nodes upgrade, they will be automatically upgraded too.

## Takedown

Then you can proceed to take down the rest of the cluster with:

```sh
kubectl delete -k hetzer/csi --kubeconfig kubeconfig.yaml
kubectl delete -k hetzer/ccm --kubeconfig kubeconfig.yaml
hcloud load-balancer delete traefik
terraform destroy -auto-approve
```

Also, if you had a full-blown cluster in use, it would be best to delete the whole project in your Hetzner account directly as operators or deployments may create other resources during regular operation.

<!-- ROADMAP -->

## Roadmap

See the [open issues](https://github.com/mysticaltech/kube-hetzner/issues) for a list of proposed features (and known issues).

<!-- CONTRIBUTING -->

## Contributing

Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Branch (`git checkout -b AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->

## License

The following code is distributed as-is and under the MIT License. See [LICENSE](LICENSE) for more information.

<!-- CONTACT -->

## Contributors

- Karim Naufal - [@mysticaltech](https://github.com/mysticaltech)

<!-- ACKNOWLEDGEMENTS -->

## Acknowledgements

- [k-andy](https://github.com/StarpTech/k-andy) was the starting point for this project. It wouldn't have been possible without it.
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template) that made writing this readme a lot easier.
- [k3os-hetzner](https://github.com/hughobrien/k3os-hetzner) was the inspiration for the k3os installation method.
- [Hetzner Cloud](https://www.hetzner.com) for providing a solid infrastructure and terraform package.
- [Hashicorp](https://www.hashicorp.com) for the amazing terraform framework that makes all the magic happen.
- [Rancher](https://www.rancher.com) for k3s and k3os, robust and innovative technologies that are the very core engine of this project.

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
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/karimnaufal/
[product-screenshot]: .images/kubectl-all-screenshot.png
