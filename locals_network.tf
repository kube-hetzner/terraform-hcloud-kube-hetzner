locals {
  network = {
    use_existing = length(var.network.existing_network_id) > 0

    # The first two subnets are respectively the default subnet 10.0.0.0/16 use for potientially anything and 10.1.0.0/16 used for control plane nodes.
    # the rest of the subnets are for agent nodes in each nodepools.
    ipv4_subnets = [for index in range(256) : cidrsubnet(var.network.cidr_blocks.ipv4.main, 8, index)]
  }
}
