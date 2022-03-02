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

# Making sure the hostname is set correctly
manage_etc_hosts: "localhost"
preserve_hostname: true
prefer_fqdn_over_hostname: false
hostname: ${hostname}

runcmd:
  # Activate the private network
  - systemctl reload network

  # Activate ssh configuration
  - systemctl reload sshd

  # Finishing automatic reboot via Kured setup
  - rebootmgrctl set-strategy off

  # Reduce the default number of snapshots from 2-10 number limit, to 4
  # And from 4-10 number limit important, to 2
  - snapper -c root set-config "NUMBER_LIMIT=4"
  - snapper -c root set-config "NUMBER_LIMIT_IMPORTANT=2"

