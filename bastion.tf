module "bastion" {
  count  = var.topology == "bastion" ? 1 : 0
  source = "./modules/host"

  providers = {
    hcloud = hcloud,
  }

  name                       = "${var.use_cluster_name_in_node_name ? "${var.cluster_name}-" : ""}bastion"
  base_domain                = var.base_domain
  ssh_keys                   = [local.hcloud_ssh_key_id]
  ssh_public_key             = var.ssh_public_key
  ssh_private_key            = var.ssh_private_key
  ssh_additional_public_keys = var.ssh_additional_public_keys
  firewall_ids               = [hcloud_firewall.k3s.id]
  placement_group_id         = hcloud_placement_group.bastion.id
  location                   = var.bastion_location
  server_type                = var.bastion_server_type
  ipv4_subnet                = hcloud_network_subnet.bastion
  packages_to_install        = local.packages_to_install
  dns_servers                = var.dns_servers

  private_ipv4   = cidrhost(hcloud_network_subnet.bastion.ip_range, 1)
  labels         = merge(local.labels, local.labels_bastion)
  rebootmgr_mode = "immediate"
}

resource "hcloud_network_subnet" "bastion" {
  network_id   = hcloud_network.k3s.id
  type         = "cloud"
  network_zone = var.network_region
  ip_range     = local.network_ipv4_subnets[255 - length(var.control_plane_nodepools)]
}

resource "hcloud_placement_group" "bastion" {
  name = "${var.cluster_name}-bastion"
  type = "spread"
}
