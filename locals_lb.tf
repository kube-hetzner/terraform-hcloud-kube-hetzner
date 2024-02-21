locals {
  using_klipper_lb = var.load_balancer.ingress.type == "klipper" || local.is_single_node_cluster

  has_external_load_balancer = local.using_klipper_lb || var.ingress.type == "none"
  load_balancer_name         = "${var.cluster_name}-${var.ingress.type}"

  ingress_controller_service_names = {
    "traefik" = "traefik"
    "nginx"   = "nginx-ingress-nginx-controller"
  }

  ingress_controller_install_resources = {
    "traefik" = ["traefik_ingress.yaml"]
    "nginx"   = ["nginx_ingress.yaml"]
  }

  default_ingress_namespace_mapping = {
    "traefik" = "traefik"
    "nginx"   = "nginx"
  }

  ingress_controller_namespace = var.ingress.namespace != "" ? var.ingress.namespace : lookup(local.default_ingress_namespace_mapping, var.ingress.type, "")
  ingress_replica_count        = (var.ingress.replica_count > 0) ? var.ingress.replica_count : (local.agent_count > 2) ? 3 : (local.agent_count == 2) ? 2 : 1
  ingress_max_replica_count    = (var.ingress.max_replica_count > local.ingress_replica_count) ? var.ingress.max_replica_count : local.ingress_replica_count
}
