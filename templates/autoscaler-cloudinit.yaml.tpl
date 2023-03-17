#cloud-config

debug: True

write_files:

# Script to rename the private interface to eth1
- path: /etc/cloud/rename_interface.sh
  content: |
    #!/bin/bash
    set -xeuo pipefail

    sleep 11
    
    INTERFACE=$(ip link show | awk '/^3:/{print $2}' | sed 's/://g')
    MAC=$(cat /sys/class/net/$INTERFACE/address)
    
    cat <<EOF > /etc/udev/rules.d/70-persistent-net.rules
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$MAC", NAME="eth1"
    EOF

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

- content: ${k3s_config}
  encoding: base64
  path: /tmp/k3s_config.yaml

- content: ${k3s_registries}
  encoding: base64
  path: /tmp/k3s_registries.yaml

%{ if length(dnsServers) > 0 }
# Set prepare for manual dns config
- content: |
    [main]
    dns=none
  path: /etc/NetworkManager/conf.d/dns.conf

- content: |
    %{ for server in dnsServers ~}
    nameserver ${server}
    %{ endfor }
  path: /etc/resolv.conf
  permissions: '0644'
%{ endif }

- content: |
    set -vx
    curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_SELINUX_RPM=true INSTALL_K3S_CHANNEL=${k3s_channel} INSTALL_K3S_EXEC=agent sh -
    /sbin/semodule -v -i /usr/share/selinux/packages/k3s.pp
    systemctl start k3s-agent
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
# uninstall k3s if it exists already in the snaphshot
- [/bin/sh, -c, '[ -f /usr/local/bin/k3s-uninstall.sh ] && /usr/local/bin/k3s-uninstall.sh']

# ensure that /var uses full available disk size, thanks to btrfs this is easy
- [btrfs, 'filesystem', 'resize', 'max', '/var']

%{ if sshPort != 22 }
# SELinux permission for the SSH alternative port.
- [semodule, '-vi', '/etc/selinux/sshd_t.pp']
%{ endif }

# Bounds the amount of logs that can survive on the system
- [sed, '-i', 's/#SystemMaxUse=/SystemMaxUse=3G/g', /etc/systemd/journald.conf]
- [sed, '-i', 's/#MaxRetentionSec=/MaxRetentionSec=1week/g', /etc/systemd/journald.conf]

# Reduces the default number of snapshots from 2-10 number limit, to 4 and from 4-10 number limit important, to 2
- [sed, '-i', 's/NUMBER_LIMIT="2-10"/NUMBER_LIMIT="4"/g', /etc/snapper/configs/root]
- [sed, '-i', 's/NUMBER_LIMIT_IMPORTANT="4-10"/NUMBER_LIMIT_IMPORTANT="3"/g', /etc/snapper/configs/root]

# Disable unneeded services
- [systemctl, disable, '--now', 'rebootmgr.service']

%{ if length(dnsServers) > 0 }
# Set the dns manually
- [systemctl, 'reload', 'NetworkManager']
%{ endif }

# rename network interface
- [chmod, '+x', '/etc/cloud/rename_interface.sh']
- ['/etc/cloud/rename_interface.sh']

# Enable install-k3s-agent service
- [mkdir, '-p', '/etc/rancher/k3s/']
- [cp, '-f' ,'/tmp/k3s_config.yaml', '/etc/rancher/k3s/config.yaml']
- [cp, '-f' ,'/tmp/k3s_registries.yaml', '/etc/rancher/k3s/registries.yaml']
- [systemctl, enable, 'install-k3s-agent.service']

# Reboot to activate everything
- [reboot]
