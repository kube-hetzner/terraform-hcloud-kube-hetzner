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

# Configure default routes based on public ip availability
%{if private_network_only~}
# Private-only setup: eth0 is the private interface
- [ip, route, add, default, via, '${network_gw_ipv4}', dev, 'eth0', metric, '100']
%{else~}
# Standard setup: eth0 is public, configure both IPv4 and IPv6
- [ip, route, add, default, via, '172.31.1.1', dev, 'eth0', metric, '100']
- [ip, -6, route, add, default, via, 'fe80::1', dev, 'eth0', metric, '100']
%{endif~}

# Start the install-k3s-agent service
- ['/bin/bash', '/var/pre_install/install-k3s-agent.sh']
