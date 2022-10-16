resource "hcloud_snapshot" "autoscale_image" {
    count = var.use_autoscaling_nodes ? 1 : 0

    # using control_plane here as this one is always available
    server_id = values(module.control_planes)[0].id
    description = "Initial snapshot used for autoscaling"
    labels = {
        autoscaler="true"
    }
}

resource "null_resource" "configure_autoscaling" {
  count = var.use_autoscaling_nodes ? 1 : 0

  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port           = var.ssh_port
  }

  # Upload the Rancher config
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/hcloud_autoscaler_config.yaml.tpl",
      {
        cloudinit_config = base64encode(data.cloudinit_config.autoscale-config[0].rendered)
        ipv4_subnet_id = hcloud_network_subnet.agent-autoscaler[0].id
        snapshot_id = hcloud_snapshot.autoscale_image[0].id
    })
    destination = "/var/post_install/hcloud_autoscaler_config.yaml"
  }

  # Deploy secrets, logging is automatically disabled due to sensitive variables
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=${hcloud_network.k3s.name} --dry-run=client -o yaml | kubectl apply -f -",
      "kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token} --dry-run=client -o yaml | kubectl apply -f -",
    ]
  }
}

resource "hcloud_network_subnet" "agent-autoscaler" {
  count = var.use_autoscaling_nodes ? 1 : 0

  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets[255]
}

resource "hcloud_server" "autoscaler" {
  count = var.use_autoscaling_nodes ? 1 : 0

  name        = "server"
  server_type = "cx21" # disk must be same or bigger than the image disk!
  image       = hcloud_snapshot.autoscale_image[0].id
  location    = "fsn1" # if not the same region, initial creation could take longer as the snapshot image has to be copied to the other region
  ssh_keys    = [local.hcloud_ssh_key_id]
  firewall_ids       = [hcloud_firewall.k3s.id]
#   placement_group_id = var.placement_group_id
  user_data          = data.cloudinit_config.autoscale-config[0].rendered
 lifecycle {
    ignore_changes = [
      location,
      ssh_keys,
    ]
 }
}

resource "hcloud_server_network" "autoscaler" {
  count = var.use_autoscaling_nodes ? 1 : 0

  ip        = "10.255.0.100"
  server_id = hcloud_server.autoscaler[0].id
  subnet_id = hcloud_network_subnet.agent-autoscaler[0].id
}

data "cloudinit_config" "autoscale-config" {
  count = var.use_autoscaling_nodes ? 1 : 0

  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/templates/autoscale-cloudinit.yaml.tpl",
      {
        hostname          = "letstry"
        sshPort           = 22
        sshAuthorizedKeys = concat([var.ssh_public_key], var.ssh_additional_public_keys)
        dnsServers        = var.dns_servers
        k3s_channel = var.initial_k3s_channel
        k3s_config = yamlencode({
            server        = "https://${var.use_control_plane_lb ? hcloud_load_balancer_network.control_plane.*.ip[0] : module.control_planes[keys(module.control_planes)[0]].private_ipv4_address}:6443"
            token         = random_password.k3s_token.result
            kubelet-arg   = ["cloud-provider=external", "volume-plugin-dir=/var/lib/kubelet/volumeplugins"]
            flannel-iface = "eth1"
            node-label    = local.default_agent_labels
            node-taint    = local.default_agent_taints
        })
      }
    )
  }
}