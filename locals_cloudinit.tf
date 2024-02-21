locals {
  cloudinit_write_files_common = <<EOT
# Script to rename the private interface to eth1 and unify NetworkManager connection naming
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

    eth0_connection=$(nmcli -g GENERAL.CONNECTION device show eth0)
    nmcli connection modify "$eth0_connection" \
      con-name eth0 \
      connection.interface-name eth0

    eth1_connection=$(nmcli -g GENERAL.CONNECTION device show eth1)
    nmcli connection modify "$eth1_connection" \
      con-name eth1 \
      connection.interface-name eth1

    systemctl restart NetworkManager
  permissions: "0744"

# Disable ssh password authentication
- content: |
    Port ${var.ssh.port}
    PasswordAuthentication no
    X11Forwarding no
    MaxAuthTries ${var.ssh.max_auth_tries}
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

# Create the kube_hetzner_selinux.te file, that allows in SELinux to not interfere with various needed services
- path: /root/kube_hetzner_selinux.te
  content: |
    module kube_hetzner_selinux 1.0;

    require {
      type kernel_t, bin_t, kernel_generic_helper_t, iscsid_t, iscsid_exec_t, var_run_t,
      init_t, unlabeled_t, systemd_logind_t, systemd_hostnamed_t, container_t,
      cert_t, container_var_lib_t, etc_t, usr_t, container_file_t, container_log_t,
      container_share_t, container_runtime_exec_t, container_runtime_t, var_log_t, proc_t;
      class key { read view };
      class file { open read execute execute_no_trans create link lock rename write append setattr unlink getattr watch };
      class sock_file { watch write create unlink };
      class unix_dgram_socket create;
      class unix_stream_socket { connectto read write };
      class dir { add_name create getattr link lock read rename remove_name reparent rmdir setattr unlink search write watch };
      class lnk_file { read create };
      class system module_request;
      class filesystem associate;
      class bpf map_create;
    }

    #============= kernel_generic_helper_t ==============
    allow kernel_generic_helper_t bin_t:file execute_no_trans;
    allow kernel_generic_helper_t kernel_t:key { read view };
    allow kernel_generic_helper_t self:unix_dgram_socket create;

    #============= iscsid_t ==============
    allow iscsid_t iscsid_exec_t:file execute;
    allow iscsid_t var_run_t:sock_file write;
    allow iscsid_t var_run_t:unix_stream_socket connectto;

    #============= init_t ==============
    allow init_t unlabeled_t:dir { add_name remove_name rmdir };
    allow init_t unlabeled_t:lnk_file create;
    allow init_t container_t:file { open read };

    #============= systemd_logind_t ==============
    allow systemd_logind_t unlabeled_t:dir search;

    #============= systemd_hostnamed_t ==============
    allow systemd_hostnamed_t unlabeled_t:dir search;

    #============= container_t ==============
    # Basic file and directory operations for specific types
    allow container_t cert_t:dir read;
    allow container_t cert_t:lnk_file read;
    allow container_t cert_t:file { read open };
    allow container_t container_var_lib_t:file { create open read write rename lock };
    allow container_t etc_t:dir { add_name remove_name write create setattr watch };
    allow container_t etc_t:file { create setattr unlink write };
    allow container_t etc_t:sock_file { create unlink };
    allow container_t usr_t:dir { add_name create getattr link lock read rename remove_name reparent rmdir setattr unlink search write };
    allow container_t usr_t:file { append create execute getattr link lock read rename setattr unlink write };

    # Additional rules for container_t
    allow container_t container_file_t:file { open read write append getattr setattr };
    allow container_t container_file_t:sock_file watch;
    allow container_t container_log_t:file { open read write append getattr setattr };
    allow container_t container_share_t:dir { read write add_name remove_name };
    allow container_t container_share_t:file { read write create unlink };
    allow container_t container_runtime_exec_t:file { read execute execute_no_trans open };
    allow container_t container_runtime_t:unix_stream_socket { connectto read write };
    allow container_t kernel_t:system module_request;
    allow container_t container_log_t:dir { read watch };
    allow container_t container_log_t:file { open read watch };
    allow container_t container_log_t:lnk_file read;
    allow container_t var_log_t:dir { add_name write };
    allow container_t var_log_t:file { create lock open read setattr write };
    allow container_t var_log_t:dir remove_name;
    allow container_t var_log_t:file unlink;
    allow container_t proc_t:filesystem associate;
    allow container_t self:bpf map_create;

# Create the k3s registries file if needed
%{if var.k3s.registries != ""}
# Create k3s registries file
- content: ${base64encode(var.k3s.registries)}
  encoding: base64
  path: /etc/rancher/k3s/registries.yaml
%{endif}

# Apply new DNS config
%{if length(var.network.dns_servers) > 0}
# Set prepare for manual dns config
- content: |
    [main]
    dns=none
  path: /etc/NetworkManager/conf.d/dns.conf

- content: |
    %{for server in var.network.dns_servers~}
    nameserver ${server}
    %{endfor}
  path: /etc/resolv.conf
  permissions: '0644'
%{endif}
EOT

  cloudinit_runcmd_common = <<EOT
# ensure that /var uses full available disk size, thanks to btrfs this is easy
- [btrfs, 'filesystem', 'resize', 'max', '/var']

# SELinux permission for the SSH alternative port
%{if var.ssh.port != 22}
# SELinux permission for the SSH alternative port.
- [semanage, port, '-a', '-t', ssh_port_t, '-p', tcp, '${var.ssh.port}']
%{endif}

# Create and apply the necessary SELinux module for kube-hetzner
- [checkmodule, '-M', '-m', '-o', '/root/kube_hetzner_selinux.mod', '/root/kube_hetzner_selinux.te']
- ['semodule_package', '-o', '/root/kube_hetzner_selinux.pp', '-m', '/root/kube_hetzner_selinux.mod']
- [semodule, '-i', '/root/kube_hetzner_selinux.pp']
- [setsebool, '-P', 'virt_use_samba', '1']
- [setsebool, '-P', 'domain_kernel_load_modules', '1']

# Disable rebootmgr service as we use kured instead
- [systemctl, disable, '--now', 'rebootmgr.service']

%{if length(var.network.dns_servers) > 0}
# Set the dns manually
- [systemctl, 'reload', 'NetworkManager']
%{endif}

# Bounds the amount of logs that can survive on the system
- [sed, '-i', 's/#SystemMaxUse=/SystemMaxUse=3G/g', /etc/systemd/journald.conf]
- [sed, '-i', 's/#MaxRetentionSec=/MaxRetentionSec=1week/g', /etc/systemd/journald.conf]

# Reduces the default number of snapshots from 2-10 number limit, to 4 and from 4-10 number limit important, to 2
- [sed, '-i', 's/NUMBER_LIMIT="2-10"/NUMBER_LIMIT="4"/g', /etc/snapper/configs/root]
- [sed, '-i', 's/NUMBER_LIMIT_IMPORTANT="4-10"/NUMBER_LIMIT_IMPORTANT="3"/g', /etc/snapper/configs/root]

# Allow network interface
- [chmod, '+x', '/etc/cloud/rename_interface.sh']

# Restart the sshd service to apply the new config
- [systemctl, 'restart', 'sshd']

# Make sure the network is up
- [systemctl, restart, NetworkManager]
- [systemctl, status, NetworkManager]
- [ip, route, add, default, via, '172.31.1.1', dev, 'eth0']

# Cleanup some logs
- [truncate, '-s', '0', '/var/log/audit/audit.log']
EOT
}
