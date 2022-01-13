output "controlplanes_public_ip" {
  value       = concat([hcloud_server.first_control_plane.ipv4_address], hcloud_server.control_planes.*.ipv4_address)
  description = "The public IP addresses of the controlplane server."
}

output "agents_public_ip" {
  value       = hcloud_server.agents.*.ipv4_address
  description = "The public IP addresses of the agent server."
}

output "traefik_public_ip" {
  value       = data.hcloud_load_balancer.lb11.ipv4
  description = "IPv4 Address of the Load Balancer"
}
