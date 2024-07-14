locals {
  server_numbers_map = { for idx, server_number in var.server_numbers : tostring(server_number) => server_number }
}

data "hetzner-robot_server" "servers" {
  for_each = local.server_numbers_map
  server_number = each.key
}

output "servers_info" {
  value = {
    for k, v in data.hetzner-robot_server.servers :
    k => {
      ip     = v.server_ip
      name   = v.server_name
      status = v.status
    }
  }
}
