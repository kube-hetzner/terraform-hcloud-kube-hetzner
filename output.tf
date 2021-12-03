output "controlplanes_public_ip" {
  value       = concat([hcloud_server.first_control_plane.ipv4_address], hcloud_server.control_planes.*.ipv4_address)
  description = "The public IP addresses of the controlplane server."
}

output "agents_public_ip" {
  value       = hcloud_server.agents.*.ipv4_address
  description = "The public IP addresses of the agent server."
}
