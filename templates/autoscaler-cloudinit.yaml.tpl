instance-id: iid-abcde001

#cloud-config

debug: True

bootcmd:
# uninstall k3s if it exists already in the snaphshot
- [/bin/sh, -c, '[ -f /usr/local/bin/k3s-uninstall.sh ] && /usr/local/bin/k3s-uninstall.sh']

write_files:

# Configure the private network interface
- content: |
    BOOTPROTO='dhcp'
    STARTMODE='auto'
  path: /etc/sysconfig/network/ifcfg-eth1

# Disable ssh password authentication
- content: |
    Port ${sshPort}
    PasswordAuthentication no
    X11Forwarding no
    MaxAuthTries 2
    AllowTcpForwarding no
    AllowAgentForwarding no
    AuthorizedKeysFile .ssh/authorized_keys
  path: /etc/ssh/sshd_config.d/kube-hetzner.conf

# Set reboot method as "kured"
- content: |
    REBOOT_METHOD=kured
  path: /etc/transactional-update.conf

# Create the sshd_t.pp file, that allows in SELinux custom SSH ports via "semodule -i",
# the encoding is binary in base64, created on a test machine with "audit2allow -a -M sshd_t",
# it is only applied when the port is different then 22, see below in the runcmd section.
- content: !!binary |
    j/98+QEAAAABAAAAEAAAAI3/fPkPAAAAU0UgTGludXggTW9kdWxlAgAAABUAAAABAAAACAAAAAAA
    AAAGAAAAc3NoZF90AwAAADEuMEAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAIAAAAKAAAAAAAAAAIA
    AAABAAAAAQAAAAAAAAB0Y3Bfc29ja2V0CQAAAAEAAABuYW1lX2JpbmQDAAAAAAAAAAEAAAABAAAA
    AQAAAAAAAABkaXIFAAAAAQAAAHdyaXRlAQAAAAEAAAAIAAAAAQAAAAAAAABvYmplY3RfckAAAAAA
    AAAAAAAAAEAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAABAAAAAQA
    AAARAAAAAQAAAAEAAAABAAAAAAAAAEAAAAAAAAAAAAAAAGNocm9ueWRfdmFyX3J1bl90EQAAAAIA
    AAABAAAAAQAAAAAAAABAAAAAAAAAAAAAAAB1bnJlc2VydmVkX3BvcnRfdAgAAAADAAAAAQAAAAEA
    AAAAAAAAQAAAAAAAAAAAAAAAd2lja2VkX3QGAAAABAAAAAEAAAABAAAAAAAAAEAAAAAAAAAAAAAA
    AHNzaGRfdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAABAAAAAAAAAAAA
    AAACAAAAAQAAAAAAAABAAAAAQAAAAAEAAAAAAAAACAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAA
    AEAAAAABAAAAAAAAAAIAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAEAAAACAAAAAQAAAAEAAAAAAAAA
    QAAAAEAAAAABAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAAQAAAAAAAAAB
    AAAAAAAAAEAAAAAAAAAAAAAAAAAAAAABAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAA
    AAAAAAAAQAAAAEAAAAABAAAAAAAAAAMAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAEAAAAABAAAAAAAA
    AA8AAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAA
    AgAAAEAAAABAAAAAAQAAAAAAAAABAAAAAAAAAEAAAABAAAAAAQAAAAAAAAABAAAAAAAAAEAAAAAA
    AAAAAAAAAEAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAEAA
    AAAAAAAAAAAAAEAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAKAAAA
    dGNwX3NvY2tldAEAAAABAAAAAQAAAAMAAABkaXIBAAAAAQAAAAEAAAABAAAACAAAAG9iamVjdF9y
    AgAAAAEAAAABAAAABAAAABEAAABjaHJvbnlkX3Zhcl9ydW5fdAEAAAABAAAAAQAAABEAAAB1bnJl
    c2VydmVkX3BvcnRfdAEAAAABAAAAAQAAAAgAAAB3aWNrZWRfdAEAAAABAAAAAQAAAAYAAABzc2hk
    X3QBAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==
  path: /etc/selinux/sshd_t.pp

- owner: root:root
  path: /etc/rancher/k3s/config.yaml
  encoding: base64
  content: ${base64encode(k3s_config)}

- owner: root:root
  path: /root/install-k3s-agent.sh
  permissions: '0600'
  content: |
      #!/bin/sh
      set -e

      # old k3s is deleted with bootcmd
      
      # run installer. Not the best way to serve directly from a public server, but works for now
      curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_SELINUX_RPM=true INSTALL_K3S_CHANNEL=${k3s_channel} INSTALL_K3S_EXEC=agent sh - 

      # install selinux module
      /sbin/semodule -v -i /usr/share/selinux/packages/k3s.pp

# Add new authorized keys
ssh_deletekeys: true

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

# ensure that /var uses full available disk size, thanks to btrfs this is easy
- [btrfs, 'filesystem', 'resize', 'max', '/var']

%{ if sshPort != 22 }
# SELinux permission for the SSH alternative port.
- [semodule, '-vi', '/etc/selinux/sshd_t.pp']
%{ endif }

# As above, make sure the hostname is not reset
- [sed, '-i', 's/NETCONFIG_NIS_SETDOMAINNAME="yes"/NETCONFIG_NIS_SETDOMAINNAME="no"/g', /etc/sysconfig/network/config]
- [sed, '-i', 's/DHCLIENT_SET_HOSTNAME="yes"/DHCLIENT_SET_HOSTNAME="no"/g', /etc/sysconfig/network/dhcp]

%{ if length(dnsServers) > 0 }
# We set the user provided DNS servers, or leave the value empty to default to Hetzners
- [sed, '-i', 's/NETCONFIG_DNS_STATIC_SERVERS=""/NETCONFIG_DNS_STATIC_SERVERS="${join(" ", dnsServers)}"/g', /etc/sysconfig/network/config]
%{ endif }

# Bounds the amount of logs that can survive on the system
- [sed, '-i', 's/#SystemMaxUse=/SystemMaxUse=3G/g', /etc/systemd/journald.conf]
- [sed, '-i', 's/#MaxRetentionSec=/MaxRetentionSec=1week/g', /etc/systemd/journald.conf]

# Reduces the default number of snapshots from 2-10 number limit, to 4 and from 4-10 number limit important, to 2
- [sed, '-i', 's/NUMBER_LIMIT="2-10"/NUMBER_LIMIT="4"/g', /etc/snapper/configs/root]
- [sed, '-i', 's/NUMBER_LIMIT_IMPORTANT="4-10"/NUMBER_LIMIT_IMPORTANT="3"/g', /etc/snapper/configs/root]

# Disables unneeded services
- [systemctl, 'restart', 'sshd']
- [systemctl, disable, '--now', 'rebootmgr.service']

# install k3s
- [/bin/sh, /root/install-k3s-agent.sh]

# start k3s-agent service
- [systemctl, 'start', 'k3s-agent']
