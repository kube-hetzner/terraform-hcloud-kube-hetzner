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
    A fully automated, optimized and auto-upgradable, HA-able, k3s cluster on <a href="https://hetzner.com" target="_blank">Hetzner Cloud</a> 🤑
  </p>
  <hr />
  <br />
</p>

## About The Project

![Product Name Screen Shot][product-screenshot]

[Hetzner Cloud](https://hetzner.com) is a good cloud provider that offers very affordable prices for cloud instances. The goal of this project was to create an optimal Kubernetes installation with it. We wanted functionality that was as close as possible to GKE's auto-pilot.

Here's what is working at the moment:

- Lightweight and resource-efficient Kubernetes with [k3s](https://github.com/k3s-io/k3s), and Fedora nodes to take advantage of the latest Linux kernels.
- Optimal [Cilium](https://github.com/cilium/cilium) CNI with full BPF support, and Kube-proxy replacement. It uses the Hetzner private subnet underneath to communicate between the nodes, as for the tunneling we use Geneve by default, but native routing also works.
- Automatic OS upgrades, supported by [kured](https://github.com/weaveworks/kured) that initiate a reboot of the node only when necessary and after having drained it properly.
- Automatic HA by setting the required number of servers and agents nodes.
- Automatic k3s upgrade by using Rancher's [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) and tracking the latest 1.x stable branch.
- Optional [Nginx ingress controller](https://kubernetes.github.io/ingress-nginx/) that will automatically use Hetzner's private network to allocate a Hetzner load balancer.

It uses Terraform to deploy as it's easy to use, and Hetzner provides a great [Hetzner Terraform Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs).

<!-- GETTING STARTED -->

## Getting started

Follow those simple steps and your world cheapest Kube cluster will be up and running in no time.

### Prerequisites

First and foremost, you need to have a Hetzner Cloud account. You can sign up for free [here](https://hetzner.com/cloud/).

Then you'll need you have both the [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) and [helm](https://helm.sh/docs/intro/install/), and [kubectl](https://kubernetes.io/docs/tasks/tools/) cli installed. The easiest way is to use the [gofish](https://gofi.sh/#install) package manager to install them.

```sh
gofish install terraform
gofish install kubectl
gofish install helm
```

### Creating terraform.tfvars

1. Create a project in your Hetzner Cloud Console, and go to **Security > API Tokens** of that project to grab the API key.
2. Generate an ssh key pair for your cluster, unless you already have one that you'd like to use.
3. Rename terraform.tfvars.example to terraform.tfvars and replace the values from steps 1 and 2.

### Customize other variables (Optional)

The number of control plane nodes and worker nodes, and the Hetzner datacenter location, can be customized by adding the variables to your newly created terraform.tfvars file.

See the default values in the [variables.tf](variables.tf) file, they correspond to (you can copy-paste and customize):

```tfvars
servers_num = 2
agents_num = 2
location = "fsn1"
agent_server_type = "cx21"
control_plane_server_type = "cx11"
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

To get the path, of course, you could use the `pwd` command.

### Ingress Controller (Optional)

To have a complete and useful setup, it is ideal to have an ingress controller running and it turns out that the Hetzner Cloud Controller allows us to automatically deploy a Hetzner Load Balancer that can be used by the ingress controller. We have chosen to use the Nginx ingress controller that you can install with the following command:

```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install --values=manifests/helm/nginx/values.yaml ingress-nginx ingress-nginx/ingress-nginx -n kube-system
```

_Note that the default geographic location and instance type of the load balancer can be changed by editing the [values.yaml](manifests/helm/nginx/values.yaml) file._

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
ssh root@xxx.xxx.xxx.xxx -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no
```

### Cilium commands

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

### Automatic upgrade

The nodes and k3s versions are configured to self-upgrade unless you turn that feature off.

- To turn OS upgrade off, log in to each node and issue:

```sh
systemctl disable --now dnf-automatic.timer
```

- To turn off k3s upgrade, use kubectl to set the k3s_upgrade label to false for each node (replace the node-name in the command):

```sh
kubectl label node node-name k3s_upgrade=false
```

### Individual components upgrade

To upgrade individual components, you can use the following commands:

- Hetzner CCM

```sh
kubectl apply -f https://raw.githubusercontent.com/mysticaltech/kube-hetzner/master/manifests/hcloud-ccm-net.yaml
```

- Hetzner CSI

```sh
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/master/deploy/kubernetes/hcloud-csi.yml
```

- Rancher's system upgrade controller

```sh
kubectl apply -f https://raw.githubusercontent.com/rancher/system-upgrade-controller/master/manifests/system-upgrade-controller.yaml
```

- Kured (used to reboot the nodes after upgrading and draining them)

```sh
latest=$(curl -s https://api.github.com/repos/weaveworks/kured/releases | jq -r '.[0].tag_name')
kubectl apply -f https://github.com/weaveworks/kured/releases/download/$latest/kured-$latest-dockerhub.yaml
```

- Cilium and the Nginx ingress controller

```sh
helm repo update
helm upgrade --values=manifests/helm/cilium/values.yaml cilium cilium/cilium -n kube-system
helm upgrade --values=manifests/helm/nginx/values.yaml ingress-nginx ingress-nginx/ingress-nginx -n kube-system
```

## Takedown

If you chose to install the Nginx ingress controller, you need to delete it first to release the load balancer, as follows:

```sh
helm delete ingress-nginx -n kube-system
```

Then you can proceed to taking down the rest of the cluster with:

```sh
terraform destroy -auto-approve
```

Sometimes, the Hetzner network is still in use and refused to be deleted via terraform, in that case you can force delete it with:

```sh
hcloud network delete k3s-net
```

Also, if you had a full blown cluster in use, it's best do delete the whole project in your Hetzner account directly, as there may be other ressources created via operators that are not part of this project.

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

## Contact

Karim Naufal - [@mysticaltech](https://twitter.com/mysticaltech) - karim.naufal@me.com

Project Link: [https://github.com/mysticaltech/kube-hetzner](https://github.com/mysticaltech/kube-hetzner)

<!-- ACKNOWLEDGEMENTS -->

## Acknowledgements

- [k-andy](https://github.com/StarpTech/k-andy) was the starting point for this project. It wouldn't have been possible without it.
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template) that made writing this readme a lot easier.
  <!-- MARKDOWN LINKS & IMAGES -->
  <!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

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
[product-screenshot]: .images/kubectl-pods-screenshot.png
