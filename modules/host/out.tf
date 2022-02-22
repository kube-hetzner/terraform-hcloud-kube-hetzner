output "ipv4_address" {
  value = hcloud_server.server.ipv4_address
}

output "private_ipv4_address" {
  value = var.ip
}

output "name" {
  value = hcloud_server.server.name
}

output "id" {
  value = hcloud_server.server.id
}
