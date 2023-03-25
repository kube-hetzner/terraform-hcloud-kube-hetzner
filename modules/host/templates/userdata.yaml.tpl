#cloud-config

debug: True

write_files:

# Script to rename the private interface to eth1
- path: /etc/cloud/rename_interface.sh
  content: |
    #!/bin/bash
    set -euo pipefail

    sleep 11
    
    INTERFACE=$(ip link show | awk '/^3:/{print $2}' | sed 's/://g')
    MAC=$(cat /sys/class/net/$INTERFACE/address)
    
    cat <<EOF > /etc/udev/rules.d/70-persistent-net.rules
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$MAC", NAME="eth1"
    EOF

    ip link set $INTERFACE down
    ip link set $INTERFACE name eth1
    ip link set eth1 up

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

# Create Rancher repo config
- content: |
    [rancher-k3s-common-stable]
    name=Rancher K3s Common (stable)
    baseurl=https://rpm.rancher.io/k3s/stable/common/microos/noarch
    enabled=1
    gpgcheck=1
    repo_gpgcheck=0
    gpgkey=https://rpm.rancher.io/public.key
  path: /etc/zypp/repos.d/rancher-k3s-common.repo

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

# Same process as above to allow iscsid to be started correctly when using Longhorn.
- content: !!binary |
    j/98+QEAAAABAAAAEAAAAI3/fPkPAAAAU0UgTGludXggTW9kdWxlAgAAABUAAAABAAAACAAAAAAA
    AAAYAAAAbXlfaXNjc2lkX3BvbGljeV91cGRhdGVkAwAAADEuMEAAAAAAAAAAAAAAAAAAAAAAAAAA
    AgAAAAIAAAADAAAAAAAAAAEAAAABAAAAAQAAAAAAAABkaXIIAAAAAQAAAGFkZF9uYW1lCAAAAAAA
    AAACAAAAAQAAAAEAAAAAAAAAbG5rX2ZpbGUGAAAAAQAAAGNyZWF0ZQEAAAABAAAACAAAAAEAAAAA
    AAAAb2JqZWN0X3JAAAAAAAAAAAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAEAA
    AAAAAAAAAAAAAAIAAAACAAAACwAAAAIAAAABAAAAAQAAAAAAAABAAAAAAAAAAAAAAAB1bmxhYmVs
    ZWRfdAYAAAABAAAAAQAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAaW5pdF90AAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAABAAAAAQAAAAEAAAAAAAAAAAAAAAIAAAABAAAAAAAAAEAAAABAAAAA
    AQAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAQAAAAAEAAAAAAAAAAgAAAAAAAABA
    AAAAAAAAAAAAAAAAAAAAAQAAAAEAAAABAAAAAQAAAAAAAABAAAAAQAAAAAEAAAAAAAAAAQAAAAAA
    AABAAAAAAAAAAAAAAAAAAAAAQAAAAEAAAAABAAAAAAAAAAIAAAAAAAAAQAAAAAAAAAAAAAAAAAAA
    AAEAAAACAAAAAQAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAABAAAAAQAAAAAEAAAAAAAAA
    AwAAAAAAAABAAAAAAAAAAAAAAABAAAAAQAAAAAEAAAAAAAAAAwAAAAAAAABAAAAAAAAAAAAAAABA
    AAAAAAAAAAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAACAAAAQAAAAEAAAAABAAAAAAAAAAEA
    AAAAAAAAQAAAAEAAAAABAAAAAAAAAAEAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAA
    AAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAA
    QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAMAAABkaXIBAAAAAQAAAAEAAAAIAAAAbG5r
    X2ZpbGUBAAAAAQAAAAEAAAABAAAACAAAAG9iamVjdF9yAgAAAAEAAAABAAAAAgAAAAsAAAB1bmxh
    YmVsZWRfdAEAAAABAAAAAQAAAAYAAABpbml0X3QBAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAA==
  path: /etc/selinux/iscsid_policy.pp

%{ if k3sRegistries != "" }
# Create k3s registries file
- content: ${base64encode(k3sRegistries)}
  encoding: base64
  path: /etc/rancher/k3s/registries.yaml
%{ endif }

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

%{ if sshPort != 22 }
# SELinux permission for the SSH alternative port.
- [semodule, '-vi', '/etc/selinux/sshd_t.pp']
%{ endif }

- [semodule, '-vi', '/etc/selinux/iscsid_policy.pp']

# Bounds the amount of logs that can survive on the system
- [sed, '-i', 's/#SystemMaxUse=/SystemMaxUse=3G/g', /etc/systemd/journald.conf]
- [sed, '-i', 's/#MaxRetentionSec=/MaxRetentionSec=1week/g', /etc/systemd/journald.conf]

# Reduces the default number of snapshots from 2-10 number limit, to 4 and from 4-10 number limit important, to 2
- [sed, '-i', 's/NUMBER_LIMIT="2-10"/NUMBER_LIMIT="4"/g', /etc/snapper/configs/root]
- [sed, '-i', 's/NUMBER_LIMIT_IMPORTANT="4-10"/NUMBER_LIMIT_IMPORTANT="3"/g', /etc/snapper/configs/root]

%{ if length(dnsServers) > 0 }
# Set the dns manually
- [systemctl, 'reload', 'NetworkManager']
%{ endif }

# Disables unneeded services
- [systemctl, 'restart', 'sshd']
- [systemctl, disable, '--now', 'rebootmgr.service']

# make rename_service executable
- [chmod, '+x', '/etc/cloud/rename_interface.sh']
