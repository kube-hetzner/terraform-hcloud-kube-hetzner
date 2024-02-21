locals {
  rancher_values = var.rancher.values != "" ? var.rancher.values : <<EOT
hostname: "${var.rancher.hostname != "" ? var.rancher.hostname : var.load_balancer.ingress.hostname}"
replicas: ${length(local.control_plane_nodes)}
bootstrapPassword: "${length(var.rancher_bootstrap_password) == 0 ? resource.random_password.rancher_bootstrap[0].result : var.rancher_bootstrap_password}"
global:
  cattle:
    psp:
      enabled: false
  EOT
}
