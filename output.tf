output "controlplanes_public_ip" {
  value       = concat([hcloud_server.first_control_plane.ipv4_address], hcloud_server.control_planes.*.ipv4_address)
  description = "The public IP addresses of the controlplane server."
}

output "agents_public_ip" {
  value       = hcloud_server.agents.*.ipv4_address
  description = "The public IP addresses of the agent server."
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
