#cloud-config
write_files:

# Configure private network
- content: |
    BOOTPROTO='dhcp'
    STARTMODE='auto'
  path: /etc/sysconfig/network/ifcfg-eth1

# Disable ssh password authentication
- content: |
    PasswordAuthentication no
    X11Forwarding no
    MaxAuthTries 2
    AllowTcpForwarding no
    AllowAgentForwarding no
    AuthorizedKeysFile .ssh/authorized_keys
  path: /etc/ssh/sshd_config.d/kube-hetzner.conf

# Setting the right reboot mode
- content: | 
    REBOOT_METHOD=rebootmgr
  path: /etc/transactional-update.conf

# Add ssh authorized keys
ssh_authorized_keys:
%{ for key in sshAuthorizedKeys ~}
  - ${key}
%{ endfor ~}

runcmd:

# Activate the private network
- systemctl reload network

# Activate ssh configuration
- systemctl reload sshd

# Fix hostname (during first boot)
- hostnamectl hostname ${hostname}

# Finishing automatic reboot via Kured setup
- rebootmgrctl set-strategy off