output "cluster_name" {
  value       = var.cluster_name
  description = "Shared suffix for all resources belonging to this cluster."
}

output "control_planes_public_ipv4" {
  value = [
    for obj in module.control_planes : obj.ipv4_address
  ]
  description = "The public IPv4 addresses of the controlplane server."
}

output "agents_public_ipv4" {
  value = [
    for obj in module.agents : obj.ipv4_address
  ]
  description = "The public IPv4 addresses of the agent server."
}

output "load_balancer_public_ipv4" {
  description = "The public IPv4 address of the Hetzner load balancer"
  value = local.is_single_node_cluster ? [
    for obj in module.control_planes : obj.ipv4_address
  ][0] : var.traefik_enabled == false ? null : data.hcloud_load_balancer.traefik[0].ipv4
}

output "kubeconfig_file" {
  value       = local.kubeconfig_external
  description = "Kubeconfig file content with external IP address"
  sensitive   = true
}

output "kubeconfig" {
  description = "Structured kubeconfig data to supply to other providers"
  value       = local.kubeconfig_data
  sensitive   = true
}
