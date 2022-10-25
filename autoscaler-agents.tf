locals {
  autoscaler_yaml = length(var.autoscaler_nodepools) == 0 ? "" : templatefile(
    "${path.module}/templates/autoscaler.yaml.tpl",
    {
      cloudinit_config = base64encode(data.cloudinit_config.autoscaler-config[0].rendered)
      ca_image         = var.cluster_autoscaler_image
      ca_version       = var.cluster_autoscaler_version
      ssh_key          = local.hcloud_ssh_key_id
      ipv4_subnet_id   = hcloud_network.k3s.id # for now we use the k3s network, as we cannot reference subnet-ids in autoscaler
      snapshot_id      = hcloud_snapshot.autoscaler_image[0].id
      firewall_id      = hcloud_firewall.k3s.id
      cluster_name     = var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""
      node_pools       = var.autoscaler_nodepools
  })
}

resource "hcloud_snapshot" "autoscaler_image" {
  count = length(var.autoscaler_nodepools) > 0 ? 1 : 0

  # using control_plane here as this one is always available
  server_id   = values(module.control_planes)[0].id
  description = "Initial snapshot used for autoscaler"
  labels = {
    autoscaler = "true"
  }
}

resource "null_resource" "configure_autoscaler" {
  count = length(var.autoscaler_nodepools) > 0 ? 1 : 0

  triggers = {
    template = local.autoscaler_yaml
  }
  connection {
    user           = "root"
    private_key    = var.ssh_private_key
    agent_identity = local.ssh_agent_identity
    host           = module.control_planes[keys(module.control_planes)[0]].ipv4_address
    port           = var.ssh_port
  }

  # Upload the autoscaler resource defintion
  provisioner "file" {
    content     = local.autoscaler_yaml
    destination = "/tmp/autoscaler.yaml"
  }

  # Create/Apply the definition
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "kubectl apply -f /tmp/autoscaler.yaml",
    ]
  }

  depends_on = [
    null_resource.first_control_plane,
    hcloud_snapshot.autoscaler_image
  ]
}

data "cloudinit_config" "autoscaler-config" {
  count = length(var.autoscaler_nodepools) > 0 ? 1 : 0

  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/templates/autoscaler-cloudinit.yaml.tpl",
      {
        hostname          = "autoscaler"
        sshPort           = var.ssh_port
        sshAuthorizedKeys = concat([var.ssh_public_key], var.ssh_additional_public_keys)
        dnsServers        = var.dns_servers
        k3s_channel       = var.initial_k3s_channel
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
