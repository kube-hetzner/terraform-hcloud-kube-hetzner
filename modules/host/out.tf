output "ipv4_address" {
  value = hcloud_server.server.ipv4_address
}

output "ipv6_address" {
  value = hcloud_server.server.ipv6_address
}

output "private_ipv4_address" {
  value = hcloud_server_network.server.ip
}

output "name" {
  value = hcloud_server.server.name
}

output "id" {
  value = hcloud_server.server.id
}
