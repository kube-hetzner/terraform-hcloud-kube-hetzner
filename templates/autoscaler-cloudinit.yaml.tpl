#cloud-config

debug: True

write_files:

${cloudinit_write_files_common}

- content: ${base64encode(k3s_config)}
  encoding: base64
  path: /tmp/config.yaml

- content: ${base64encode(install_k3s_agent_script)}
  encoding: base64
  path: /var/pre_install/install-k3s-agent.sh

# Apply DNS config
%{ if has_dns_servers ~}
manage_resolv_conf: true
resolv_conf:
  nameservers:
%{ for dns_server in dns_servers ~}
    - ${dns_server}
%{ endfor ~}
%{ endif ~}

# Add ssh authorized keys
ssh_authorized_keys:
%{ for key in sshAuthorizedKeys ~}
  - ${key}
%{ endfor ~}

# Resize /var, not /, as that's the last partition in MicroOS image.
growpart:
    devices: ["/var"]

# Make sure the hostname is set correctly
hostname: ${hostname}
preserve_hostname: true

runcmd:

${cloudinit_runcmd_common}

# Configure default route based on public ip availability
%{if private_network_only~}
# Private-only setup: eth0 is the private interface
- [ip, route, add, default, via, '10.0.0.1', dev, 'eth0', metric, '100']
%{else~}
# Standard setup: eth0 is public, eth1 is private
- [ip, route, add, default, via, '172.31.1.1', dev, 'eth0', metric, '100']

# Ensure private network has default route (protection against DHCP changes)
- |
  set +e  # Don't fail if route exists
  # Wait for private interface to be ready
  for i in {1..30}; do
    if ip link show eth1 &>/dev/null; then
      # Add default route via private network with high metric
      ip route add default via 10.0.0.1 dev eth1 metric 20101 2>/dev/null || true
      
      # Configure NetworkManager to ignore DHCP default route on private interface
      if systemctl is-active --quiet NetworkManager; then
        NM_CONN=$(nmcli -g GENERAL.CONNECTION device show eth1 2>/dev/null | head -1)
        if [ -n "$NM_CONN" ]; then
          nmcli connection modify "$NM_CONN" ipv4.never-default yes 2>/dev/null || true
        fi
      fi
      break
    fi
    sleep 1
  done
  set -e
%{endif~}

# Start the install-k3s-agent service
- ['/bin/bash', '/var/pre_install/install-k3s-agent.sh']
