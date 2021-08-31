resource "hcloud_server" "first_control_plane" {
  name = "k3s-control-plane-0"

  image        = data.hcloud_image.linux.name
  server_type  = var.control_plane_server_type
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.k3s.id]


  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s",
    "k3s_upgrade" = "true"
  }

  user_data = data.template_cloudinit_config.init_cfg.rendered

  provisioner "remote-exec" {
    inline = var.initial_commands

    connection {
      user        = "root"
      private_key = file(var.private_key)
      host        = self.ipv4_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_TOKEN=${random_password.k3s_cluster_secret.result} sh -s - server --cluster-init --node-ip=${local.first_control_plane_network_ip} --advertise-address=${local.first_control_plane_network_ip} --tls-san=${local.first_control_plane_network_ip} ${var.k3s_server_flags}",
      "until systemctl is-active --quiet k3s.service; do sleep 1; done",
      "until kubectl get node ${self.name}; do sleep 1; done",
      "kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=${hcloud_network.k3s.name}",
      "kubectl apply -f -<<EOF\n${data.template_file.ccm_manifest.rendered}\nEOF",
      "kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token}",
      "kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/master/deploy/kubernetes/hcloud-csi.yml",
      "kubectl apply -f https://raw.githubusercontent.com/rancher/system-upgrade-controller/master/manifests/system-upgrade-controller.yaml",
      "kubectl apply -f -<<EOF\n${data.template_file.upgrade_plan.rendered}\nEOF",
      "latest=$(curl -s https://api.github.com/repos/weaveworks/kured/releases | jq -r .[0].tag_name)",
      "kubectl apply -f https://github.com/weaveworks/kured/releases/download/$latest/kured-$latest-dockerhub.yaml"
    ]

    connection {
      user        = "root"
      private_key = file(var.private_key)
      host        = self.ipv4_address
    }
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.private_key} root@${self.ipv4_address}:/etc/rancher/k3s/k3s.yaml ./kubeconfig.yaml"
  }

  provisioner "local-exec" {
    command = "sed -i -e 's/127.0.0.1/${self.ipv4_address}/g' ./kubeconfig.yaml"
  }

  provisioner "local-exec" {
    command = "helm install --values=manifests/helm/cilium/values.yaml cilium cilium/cilium -n kube-system"
  }

  network {
    network_id = hcloud_network.k3s.id
    ip         = local.first_control_plane_network_ip
  }

  depends_on = [
    hcloud_network_subnet.k3s,
    hcloud_firewall.k3s
  ]
}
