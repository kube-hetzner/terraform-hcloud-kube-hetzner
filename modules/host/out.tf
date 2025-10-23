output "ipv4_address" {
  value = hcloud_server.server.ipv4_address
}

output "ipv6_address" {
  value = hcloud_server.server.ipv6_address
}

output "private_ipv4_address" {
  # Simply return the private IP that was configured - it doesn't change based on how it's attached
  value = var.private_ipv4 != null ? var.private_ipv4 : ""
}

output "name" {
  value = hcloud_server.server.name
}

output "id" {
  value = hcloud_server.server.id
}

output "domain_assignments" {
  description = "Assignment of domain to the primary IP of the server"
  value = [
    for rdns in hcloud_rdns.server : {
      domain = rdns.dns_ptr
      ips    = [rdns.ip_address]
    }
  ]
}
