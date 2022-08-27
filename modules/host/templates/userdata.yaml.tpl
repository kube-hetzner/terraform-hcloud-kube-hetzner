#cloud-config

debug: True

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

# Create the sshd_t.pp file
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

# SELinux permission for the SSH alternative port.
- [semodule, '-i', /etc/selinux/sshd_t.pp]
- [sleep, '10']

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
- [systemctl, disable, '--now', 'rebootmgr.service']
