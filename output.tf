output "cluster_name" {
  value       = var.cluster_name
  description = "Shared suffix for all resources belonging to this cluster."
}

output "control_planes_public_ipv4" {
  value = [
    for obj in module.control_planes : obj.ipv4_address
  ]
  description = "The public IPv4 addresses of the controlplane servers."
}

output "agents_public_ipv4" {
  value = [
    for obj in module.agents : obj.ipv4_address
  ]
  description = "The public IPv4 addresses of the agent servers."
}

output "ingress_public_ipv4" {
  description = "The public IPv4 address of the Hetzner load balancer"
  value       = local.has_external_load_balancer ? module.control_planes[keys(module.control_planes)[0]].ipv4_address : data.hcloud_load_balancer.cluster[0].ipv4
}

output "ingress_public_ipv6" {
  description = "The public IPv6 address of the Hetzner load balancer"
  value       = (local.has_external_load_balancer || var.load_balancer_disable_ipv6) ? null : data.hcloud_load_balancer.cluster[0].ipv6
}

# Keeping for backward compatibility
output "kubeconfig_file" {
  value       = local.kubeconfig_external
  description = "Kubeconfig file content with external IP address"
  sensitive   = true
}

output "kubeconfig" {
  value       = local.kubeconfig_external
  description = "Kubeconfig file content with external IP address"
  sensitive   = true
}

output "kubeconfig_data" {
  description = "Structured kubeconfig data to supply to other providers"
  value       = local.kubeconfig_data
  sensitive   = true
}
