#cloud-config

write_files:

# Configure the private network interface
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
manage_etc_hosts: "localhost"

runcmd:

# As above, make sure the hostname is not reset
- [ sed, -i, 's#preserve_hostname: false#preserve_hostname: true#g', /etc/cloud/cloud.cfg]
- [ sed, -i, 's#NETCONFIG_NIS_SETDOMAINNAME="yes"#NETCONFIG_NIS_SETDOMAINNAME="no"#g', /etc/sysconfig/network/config]
- [ sed, -i, 's#DHCLIENT_SET_HOSTNAME="yes"#DHCLIENT_SET_HOSTNAME="no"#g', /etc/sysconfig/network/dhcp]

# We set Google DNS servers
- [ sed, -i, 's#NETCONFIG_DNS_STATIC_SERVERS=""#NETCONFIG_DNS_STATIC_SERVERS="1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4"#g', /etc/sysconfig/network/config]

# Bound the amount of logs that can survive on the system
- [ sed, -i, 's/#SystemMaxUse=/SystemMaxUse=3G/g', /etc/systemd/journald.conf]
- [ sed, -i, 's/#MaxRetentionSec=/MaxRetentionSec=1week/g', /etc/systemd/journald.conf]

# Activate the private network
- systemctl reload network

# Activate ssh configuration
- systemctl reload sshd

# Finishing automatic reboot via Kured setup
- echo 'REBOOT_METHOD=kured' > /etc/transactional-update.conf
- rebootmgrctl set-strategy off

# Reduce the default number of snapshots from 2-10 number limit, to 4
# And from 4-10 number limit important, to 2
- snapper -c root set-config "NUMBER_LIMIT=4"
- snapper -c root set-config "NUMBER_LIMIT_IMPORTANT=2"
