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
    content = templatefile("${path.module}/templates/master.tpl", {
      name           = self.name
      ssh_public_key = local.ssh_public_key
      k3s_token      = random_password.k3s_token.result
      master_ip      = local.first_control_plane_network_ip
    })
    destination = "/tmp/config.yaml"

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
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

  # Install k3os
  provisioner "remote-exec" {
    inline = local.microOS_install_commands

    connection {
      user           = "root"
      private_key    = local.ssh_private_key
      agent_identity = local.ssh_identity
      host           = self.ipv4_address
    }
  }
  /*
  # Wait for MicroOS to be ready and fetch kubeconfig.yaml
  provisioner "local-exec" {
    command = <<-EOT
      sleep 60 && ping ${self.ipv4_address} | grep --line-buffered "bytes from" | head -1 && sleep 100 && scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local.ssh_identity_file} rancher@${self.ipv4_address}:/etc/rancher/k3s/k3s.yaml ${path.module}/kubeconfig.yaml
      sed -i -e 's/127.0.0.1/${self.ipv4_address}/g' ${path.module}/kubeconfig.yaml
    EOT
  }

  # Install Hetzner CCM and CSI
  provisioner "local-exec" {
    command = <<-EOT
      kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=${hcloud_network.k3s.name} --kubeconfig ${path.module}/kubeconfig.yaml
      kubectl apply -k ${dirname(local_file.hetzner_ccm_config.filename)} --kubeconfig ${path.module}/kubeconfig.yaml
      kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token} --kubeconfig ${path.module}/kubeconfig.yaml
      kubectl apply -k ${dirname(local_file.hetzner_csi_config.filename)} --kubeconfig ${path.module}/kubeconfig.yaml
    EOT
  }

  # Configure the Traefik ingress controller
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.traefik_config.filename} --kubeconfig ${path.module}/kubeconfig.yaml"
  }
*/
  network {
    network_id = hcloud_network.k3s.id
    ip         = local.first_control_plane_network_ip
  }

  depends_on = [
    hcloud_network_subnet.k3s,
    hcloud_firewall.k3s
  ]
}
