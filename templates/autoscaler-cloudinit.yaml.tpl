#cloud-config

debug: True

write_files:

${cloudinit_write_files_common}

- content: ${base64encode(k3s_config)}
  encoding: base64
  path: /etc/rancher/k3s/config.yaml

- content: ${base64encode(install_k3s_agent_script)}
  encoding: base64
  path: /var/pre_install/install-k3s-agent.sh

- content: |
    [Unit]
    Description=Run install-k3s-agent once at boot time
    After=network-online.target

    [Service]
    Type=oneshot
    ExecStart=/bin/sh /var/pre_install/install-k3s-agent.sh

    [Install]
    WantedBy=network-online.target
  permissions: '0644'
  path: /etc/systemd/system/install-k3s-agent.service

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

# Enable install-k3s-agent service
- [systemctl, enable, 'install-k3s-agent.service']

# reboot!
power_state:
    delay: now
    mode: reboot
    message: MicroOS rebooting to reflect changes
    condition: true
