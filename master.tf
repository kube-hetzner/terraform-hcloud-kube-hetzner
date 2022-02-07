resource "hcloud_server" "first_control_plane" {
  name = "k3s-control-plane-0"

  image              = data.hcloud_image.linux.name
  rescue             = "linux64"
  server_type        = var.control_plane_server_type
  location           = var.location
  ssh_keys           = [hcloud_ssh_key.k3s.id]
  firewall_ids       = [hcloud_firewall.k3s.id]
  placement_group_id = hcloud_placement_group.k3s_placement_group.id

  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/config.ign.tpl", {
      name           = self.name
      ssh_public_key = local.ssh_public_key
    })
    destination = "/root/config.ign"

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  # Install MicroOS
  provisioner "remote-exec" {
    inline = local.MicroOS_install_commands

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  # Issue a reboot command
  provisioner "local-exec" {
    command = "ssh ${local.ssh_args} root@${self.ipv4_address} '(sleep 2; reboot)&'; sleep 3"
  }

  # Wait for MicroOS to reboot and be ready
  provisioner "local-exec" {
    command = "ping ${self.ipv4_address} | grep --line-buffered 'bytes from' | head -1 && sleep 10 && until ssh ${local.ssh_args} -o ConnectTimeout=2 root@${self.ipv4_address} true; do sleep 1; done"
  }

  # Generating k3s master config file
  provisioner "file" {
    content = templatefile("${path.module}/templates/master_config.yaml.tpl", {
      node_ip                           = local.first_control_plane_network_ip
      token                             = random_password.k3s_token.result
      node_name                         = self.name
      allow_scheduling_on_control_plane = var.allow_scheduling_on_control_plane
    })
    destination = "/etc/rancher/k3s/config.yaml"

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }
  # Run the first control plane
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      # first we disable automatic reboot (after transactional updates), and configure the reboot method as kured
      "rebootmgrctl set-strategy off && echo 'REBOOT_METHOD=kured' > /etc/transactional-update.conf",
      # then we initiate the cluster
      "systemctl --now enable k3s-server",
    ]

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }

  # Get the Kubeconfig, and wait for the node to be available
  provisioner "local-exec" {
    command = <<-EOT
      set -ex
      sleep 30
      scp ${local.ssh_args} root@${self.ipv4_address}:/etc/rancher/k3s/k3s.yaml ${path.module}/kubeconfig.yaml
      sed -i -e 's/127.0.0.1/${self.ipv4_address}/g' ${path.module}/kubeconfig.yaml
      sleep 10 && until kubectl get node ${self.name} --kubeconfig ${path.module}/kubeconfig.yaml; do sleep 5; done
    EOT
  }

  # Install the Hetzner CCM and CSI
  provisioner "local-exec" {
    command = <<-EOT
      set -ex
      kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=${hcloud_network.k3s.name} --kubeconfig ${path.module}/kubeconfig.yaml
      kubectl apply -k ${dirname(local_file.hetzner_ccm_config.filename)} --kubeconfig ${path.module}/kubeconfig.yaml
      kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token} --kubeconfig ${path.module}/kubeconfig.yaml
      kubectl apply -k ${dirname(local_file.hetzner_csi_config.filename)} --kubeconfig ${path.module}/kubeconfig.yaml
    EOT
  }

  # Install Kured
  provisioner "local-exec" {
    command = <<-EOT
      set -ex
      kubectl -n kube-system apply -k ${dirname(local_file.kured_config.filename)} --kubeconfig ${path.module}/kubeconfig.yaml
    EOT
  }

  # Configure the Traefik ingress controller
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.traefik_config.filename} --kubeconfig ${path.module}/kubeconfig.yaml"
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
