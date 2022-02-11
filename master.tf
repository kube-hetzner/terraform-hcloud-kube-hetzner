resource "hcloud_server" "first_control_plane" {
  name = "k3s-control-plane-0"

  image              = data.hcloud_image.linux.name
  rescue             = "linux64"
  server_type        = var.control_plane_server_type
  location           = var.location
  ssh_keys           = [hcloud_ssh_key.k3s.id]
  firewall_ids       = [hcloud_firewall.k3s.id]
  placement_group_id = hcloud_placement_group.k3s.id

  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = self.ipv4_address
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/config.ign.tpl", {
      name           = self.name
      ssh_public_key = local.ssh_public_key
    })
    destination = "/root/config.ign"
  }

  # Install MicroOS
  provisioner "remote-exec" {
    inline = local.MicroOS_install_commands
  }

  # Issue a reboot command
  provisioner "local-exec" {
    command = "ssh ${local.ssh_args} root@${self.ipv4_address} '(sleep 2; reboot)&'; sleep 3"
  }

  # Wait for MicroOS to reboot and be ready
  provisioner "local-exec" {
    command = <<-EOT
      until ssh ${local.ssh_args} -o ConnectTimeout=2 root@${self.ipv4_address} true 2> /dev/null
      do
        echo "Waiting for MicroOS to reboot and become available..."
        sleep 2
      done
    EOT
  }

  # Generating k3s master config file
  provisioner "file" {
    content = yamlencode({
      node-name                = self.name
      cluster-init             = true
      disable-cloud-controller = true
      disable                  = ["servicelb", "local-storage"]
      flannel-iface            = "eth1"
      kubelet-arg              = "cloud-provider=external"
      node-ip                  = local.first_control_plane_network_ip
      advertise-address        = local.first_control_plane_network_ip
      token                    = random_password.k3s_token.result
      node-taint               = var.allow_scheduling_on_control_plane ? [] : ["node-role.kubernetes.io/master:NoSchedule"]
    })
    destination = "/etc/rancher/k3s/config.yaml"
  }

  # Run the first control plane
  provisioner "remote-exec" {
    inline = [
      # set the hostname in a persistent fashion
      "hostnamectl set-hostname ${self.name}",
      # first we disable automatic reboot (after transactional updates), and configure the reboot method as kured
      "rebootmgrctl set-strategy off && echo 'REBOOT_METHOD=kured' > /etc/transactional-update.conf",
      # prepare a directory for our post-installation kustomizations
      "mkdir -p /tmp/post_install",
      # then we initiate the cluster
      "systemctl enable k3s-server",
      # start k3s
      "systemctl start k3s-server",
      # wait for k3s to get ready
      <<-EOT
      timeout 120 bash <<EOF
        until [ -e /etc/rancher/k3s/k3s.yaml ]; do
          echo "Waiting for kubectl config"
          sleep 1
        done
        until [[ "$(kubectl get --raw='/readyz')" == "ok" ]]; do
          echo "Waiting for cluster to become ready"
          sleep 1
        done
      EOF
      EOT
    ]
  }

  # Upload kustomization.yaml, containing Hetzner CSI & CSM, as well as kured.
  provisioner "file" {
    content     = local.post_install_kustomization
    destination = "/tmp/post_install/kustomization.yaml"
  }

  # Upload traefik config
  provisioner "file" {
    content     = local.traefik_config
    destination = "/tmp/post_install/traefik.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=${hcloud_network.k3s.name}",
      "kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token}",
      "kubectl apply -k /tmp/post_install",
      "rm -rf /tmp/post_install"
    ]
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
