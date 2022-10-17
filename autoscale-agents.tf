resource "hcloud_snapshot" "autoscale_image" {
  count = var.max_number_nodes_autoscaler != 0 ? 1 : 0

  # using control_plane here as this one is always available
  server_id   = values(module.control_planes)[0].id
  description = "Initial snapshot used for autoscaling"
  labels = {
    autoscaler = "true"
  }
}

resource "null_resource" "configure_autoscaling" {
  count = var.max_number_nodes_autoscaler != 0 ? 1 : 0

  triggers = {
    template = templatefile(
      "${path.module}/templates/autoscaler.yaml.tpl",
      {
        #cloudinit_config - we have to check if this is necessary, if so we need to recreate it, or somehow extract it from server module, up to a higher level
        cloudinit_config            = base64encode(data.cloudinit_config.autoscale-config[0].rendered)
        name                        = "autoscaling"
        server_type                 = "CPX21"
        location                    = "FSN1"
        ssh_key                     = local.hcloud_ssh_key_id
        ipv4_subnet_id              = hcloud_network_subnet.autoscaling.network_id # cannot reference subnet-ids in autoscaler
        snapshot_id                 = hcloud_snapshot.autoscale_image[0].id
        min_number_nodes_autoscaler = var.min_number_nodes_autoscaler
        max_number_nodes_autoscaler = var.max_number_nodes_autoscaler
    })
  }
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
      "${path.module}/templates/autoscaler.yaml.tpl",
      {
        #cloudinit_config - we have to check if this is necessary, if so we need to recreate it, or somehow extract it from server module, up to a higher level
        cloudinit_config            = base64encode(data.cloudinit_config.autoscale-config[0].rendered)
        name                        = "autoscaling"
        server_type                 = "CPX21"
        location                    = "FSN1"
        ssh_key                     = local.hcloud_ssh_key_id
        ipv4_subnet_id              = hcloud_network_subnet.autoscaling.network_id # cannot reference subnet-ids in autoscaler
        snapshot_id                 = hcloud_snapshot.autoscale_image[0].id
        min_number_nodes_autoscaler = var.min_number_nodes_autoscaler
        max_number_nodes_autoscaler = var.max_number_nodes_autoscaler
    })
    destination = "/tmp/autoscaler.yaml"
  }

  # Deploy secrets, logging is automatically disabled due to sensitive variables
  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "kubectl apply -f /tmp/autoscaler.yaml",
      # do we remove that also again? 
    ]
  }

  depends_on = [
    null_resource.first_control_plane,
    hcloud_network_subnet.autoscaling,
    hcloud_snapshot.autoscale_image
  ]
}

data "cloudinit_config" "autoscale-config" {
  count = var.max_number_nodes_autoscaler != 0 ? 1 : 0

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
