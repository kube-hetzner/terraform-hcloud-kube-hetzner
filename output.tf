output "controlplanes_public_ip" {
  value       = concat([module.first_control_plane.ipv4_address], module.control_planes.*.ipv4_address)
  description = "The public IP addresses of the controlplane server."
}

output "agents_public_ip" {
  value       = module.agents.*.ipv4_address
  description = "The public IP addresses of the agent server."
}

output "load_balancer_public_ip" {
  description = "The public IPv4 address of the Hetzner load balancer"
  value       = data.hcloud_load_balancer.traefik.ipv4
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
