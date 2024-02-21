locals {
  using_klipper_lb = var.load_balancer.ingress.type == "klipper" || local.is_single_node_cluster

  has_external_load_balancer = local.using_klipper_lb || var.ingress.type == "none"
  load_balancer_name         = "${var.cluster_name}-${var.ingress.type}"
}
