locals {
  base_firewall_rules = concat(
    var.firewall.ssh_source == null ? [] : [
      # Allow all traffic to the ssh port
      {
        description = "Allow Incoming SSH Traffic"
        direction   = "in"
        protocol    = "tcp"
        port        = var.ssh.port
        source_ips  = var.firewall.ssh_source
      },
    ],
    var.firewall.kube_api_source == null ? [] : [
      {
        description = "Allow Incoming Requests to Kube API Server"
        direction   = "in"
        protocol    = "tcp"
        port        = "6443"
        source_ips  = var.firewall.kube_api_source
      }
    ],
    !var.firewall.restrict_outbound_traffic ? [] : [
      # Allow basic out traffic
      ## ICMP to ping outside services
      {
        description     = "Allow Outbound ICMP Ping Requests"
        direction       = "out"
        protocol        = "icmp"
        port            = ""
        destination_ips = ["0.0.0.0/0", "::/0"]
      },
      ## DNS
      {
        description     = "Allow Outbound TCP DNS Requests"
        direction       = "out"
        protocol        = "tcp"
        port            = "53"
        destination_ips = ["0.0.0.0/0", "::/0"]
      },
      {
        description     = "Allow Outbound UDP DNS Requests"
        direction       = "out"
        protocol        = "udp"
        port            = "53"
        destination_ips = ["0.0.0.0/0", "::/0"]
      },

      ## HTTP(s)
      {
        description     = "Allow Outbound HTTP Requests"
        direction       = "out"
        protocol        = "tcp"
        port            = "80"
        destination_ips = ["0.0.0.0/0", "::/0"]
      },
      {
        description     = "Allow Outbound HTTPS Requests"
        direction       = "out"
        protocol        = "tcp"
        port            = "443"
        destination_ips = ["0.0.0.0/0", "::/0"]
      },
      ## NTP
      {
        description     = "Allow Outbound UDP NTP Requests"
        direction       = "out"
        protocol        = "udp"
        port            = "123"
        destination_ips = ["0.0.0.0/0", "::/0"]
      }
    ],
    !local.using_klipper_lb ? [] : [
      # Allow incoming web traffic for single node clusters
      # Because k3s servicelb is used, not an external load-balancer
      {
        description = "Allow Incoming HTTP Connections"
        direction   = "in"
        protocol    = "tcp"
        port        = "80"
        source_ips  = ["0.0.0.0/0", "::/0"]
      },
      {
        description = "Allow Incoming HTTPS Connections"
        direction   = "in"
        protocol    = "tcp"
        port        = "443"
        source_ips  = ["0.0.0.0/0", "::/0"]
      }
    ],
    var.firewall.block_icmp_ping_in ? [] : [
      {
        description = "Allow Incoming ICMP Ping Requests"
        direction   = "in"
        protocol    = "icmp"
        port        = ""
        source_ips  = ["0.0.0.0/0", "::/0"]
      }
    ]
  )

  # 1) create a new firewall list based on base_firewall_rules but with direction-protocol-port as key
  # this is needed to avoid duplicate rules
  # 2) do the same for var.extra_firewall_rules
  # 3) merge the two lists
  # 4) convert the merged list back to a list
  firewall_rules = values(merge({
    for rule in local.base_firewall_rules : format("%s-%s-%s", lookup(rule, "direction", "null"), lookup(rule, "protocol", "null"), lookup(rule, "port", "null")) => rule
    }, {
    for rule in var.firewall.extra_rules : format("%s-%s-%s", lookup(rule, "direction", "null"), lookup(rule, "protocol", "null"), lookup(rule, "port", "null")) => rule
    }
  ))
}
