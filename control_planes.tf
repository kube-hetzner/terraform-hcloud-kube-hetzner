module "control_planes" {
  source = "./modules/host"

  count                  = var.control_plane_count
  name                   = "${var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""}control-plane"
  ssh_keys               = [hcloud_ssh_key.k3s.id]
  public_key             = var.public_key
  private_key            = var.private_key
  additional_public_keys = var.additional_public_keys
  firewall_ids           = [hcloud_firewall.k3s.id]
  placement_group_id     = hcloud_placement_group.k3s.id
  location               = var.location
  server_type            = var.control_plane_server_type
  ipv4_subnet_id         = hcloud_network_subnet.subnet["control_plane"].id

  # We leave some room so 100 eventual Hetzner LBs that can be created perfectly safely
  # It leaves the subnet with 254 x 254 - 100 = 64416 IPs to use, so probably enough.
  private_ipv4 = cidrhost(var.network_ipv4_subnets["control_plane"], count.index + 101)

  labels = {
    "provisioner" = "terraform",
    "engine"      = "k3s"
  }

  depends_on = [
    hcloud_network_subnet.subnet
  ]
}

resource "null_resource" "control_planes" {
  count = var.control_plane_count

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
      server                   = "https://${element(module.control_planes.*.private_ipv4_address, count.index > 0 ? 0 : 1)}:6443"
      token                    = random_password.k3s_token.result
      disable-cloud-controller = true
      disable                  = ["servicelb", "local-storage", "traefik", "metric-server"]
      flannel-iface            = "eth1"
      kubelet-arg              = "cloud-provider=external"
      node-ip                  = module.control_planes[count.index].private_ipv4_address
      advertise-address        = module.control_planes[count.index].private_ipv4_address
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
      "systemctl start k3s 2> /dev/null",
      <<-EOT
      timeout 120 bash <<EOF
        until systemctl status k3s > /dev/null; do
          systemctl start k3s 2> /dev/null
          echo "Waiting for the k3s server to start..."
          sleep 2
        done
      EOF
      EOT
    ]
  }

  depends_on = [
    null_resource.first_control_plane,
    hcloud_network_subnet.subnet
  ]
}
