module "control_planes" {
  source = "./modules/host"

  count = var.servers_num - 1
  name  = "k3s-control-plane-${count.index + 1}"

  ssh_keys               = [hcloud_ssh_key.k3s.id]
  public_key             = var.public_key
  private_key            = var.private_key
  additional_public_keys = var.additional_public_keys
  firewall_ids           = [hcloud_firewall.k3s.id]
  placement_group_id     = hcloud_placement_group.k3s.id
  location               = var.location
  network_id             = hcloud_network.k3s.id
  ip                     = cidrhost(hcloud_network_subnet.k3s.ip_range, 258 + count.index)
  server_type            = var.control_plane_server_type

  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }

  hcloud_token = var.hcloud_token
}

resource "null_resource" "control_planes" {
  count = var.servers_num - 1

  triggers = {
    control_plane_id = module.control_planes[count.index].id
  }

  connection {
    user           = "root"
    private_key    = local.ssh_private_key
    agent_identity = local.ssh_identity
    host           = module.control_planes[count.index].ipv4_address
  }

  # Generating k3s server config file
  provisioner "file" {
    content = yamlencode({
      node-name                = module.control_planes[count.index].name
      server                   = "https://${local.first_control_plane_network_ip}:6443"
      token                    = random_password.k3s_token.result
      cluster-init             = true
      disable-cloud-controller = true
      disable                  = ["servicelb", "local-storage"]
      flannel-iface            = "eth1"
      kubelet-arg              = "cloud-provider=external"
      node-ip                  = cidrhost(hcloud_network_subnet.k3s.ip_range, 258 + count.index)
      advertise-address        = cidrhost(hcloud_network_subnet.k3s.ip_range, 258 + count.index)
      tls-san                  = cidrhost(hcloud_network_subnet.k3s.ip_range, 258 + count.index)
      node-taint               = var.allow_scheduling_on_control_plane ? [] : ["node-role.kubernetes.io/master:NoSchedule"]
      node-label               = var.automatically_upgrade_k3s ? ["k3s_upgrade=true"] : []
    })
    destination = "/tmp/config.yaml"
  }

  # Install k3s server
  provisioner "remote-exec" {
    inline = local.install_k3s_server
  }

  # Start the k3s server and wait for it to have started correctly
  provisioner "remote-exec" {
    inline = [
      "systemctl start k3s",
      <<-EOT
      timeout 120 bash <<EOF
        until systemctl status k3s > /dev/null; do
          systemctl start k3s
          echo "Waiting for the k3s server to start..."
          sleep 2
        done
      EOF
      EOT
    ]
  }

  depends_on = [
    null_resource.first_control_plane,
    hcloud_network_subnet.k3s
  ]
}
