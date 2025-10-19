#cloud-config

write_files:

${cloudinit_write_files_common}
%{ if os == "leapmicro" ~}
- path: /usr/local/bin/apply-k8s-selinux-policy.sh
  permissions: '0755'
  content: |
    #!/bin/bash
    # Apply comprehensive SELinux policy for K8s on Leap Micro
    
    echo "[$(date)] Starting K8s SELinux policy application" >> /var/log/k8s-selinux.log
    
    # Create the policy file
    cat > /tmp/k8s_custom_policies.te <<'EOF'
    module k8s_custom_policies 1.0;
    
    require {
        type container_t;
        type cert_t;
        type proc_t;
        type sysfs_t;
        type kernel_t;
        type init_t;
        type security_t;
        type unreserved_port_t;
        type kubernetes_port_t;
        type http_port_t;
        type hplip_port_t;
        type node_t;
        class dir { read search open getattr };
        class file { read open getattr };
        class lnk_file { read getattr };
        class tcp_socket { name_bind name_connect accept listen read write };
        class node { tcp_recv tcp_send };
        class peer recv;
        class filesystem getattr;
    }
    
    # Allow containers to read certificate directories and files
    allow container_t cert_t:dir { read search open getattr };
    allow container_t cert_t:file { read open getattr };
    
    # Allow containers to read proc filesystem (needed for metrics-server filesystem collector)
    allow container_t proc_t:file { read open getattr };
    allow container_t proc_t:dir { read search open getattr };
    allow container_t proc_t:lnk_file { read getattr };
    allow container_t proc_t:filesystem getattr;
    
    # Also allow sysfs access which is often needed alongside proc
    allow container_t sysfs_t:file { read open getattr };
    allow container_t sysfs_t:dir { read search open getattr };
    allow container_t sysfs_t:lnk_file { read getattr };
    allow container_t sysfs_t:filesystem getattr;
    
    # Allow containers to bind to kubernetes ports (including 10250 for metrics-server)
    allow container_t kubernetes_port_t:tcp_socket { name_bind name_connect accept listen };
    
    # Allow containers to bind to hplip ports (including 9100 for node-exporter)
    allow container_t hplip_port_t:tcp_socket { name_bind name_connect accept listen };
    
    # Allow containers to bind to unreserved high ports
    allow container_t unreserved_port_t:tcp_socket { name_bind name_connect accept listen };
    
    # Allow container-to-container communication (needed for readiness probes)
    allow container_t container_t:tcp_socket { name_connect accept };
    allow container_t container_t:peer recv;
    
    # Allow containers to use network nodes
    allow container_t node_t:node { tcp_recv tcp_send };
    
    # Allow containers to bind to http ports (some exporters may use these)
    allow container_t http_port_t:tcp_socket { name_bind name_connect accept listen };
    
    # Allow containers to read kernel TCP sockets (needed for metrics-server to read /proc/net/tcp)
    allow container_t kernel_t:tcp_socket { read write };
    
    # Allow containers to read SELinux status (needed for node-exporter)
    allow container_t security_t:file { read open getattr };
    
    # Allow containers to access init process information (needed for node-exporter to read mountinfo, etc.)
    allow container_t init_t:dir { read search open getattr };
    allow container_t init_t:file { read open getattr };
    allow container_t init_t:lnk_file { read getattr };
    EOF
    
    # Remove any old modules
    for mod in k8s_custom_policies k8s_comprehensive kube_hetzner_selinux; do
        semodule -r $mod 2>/dev/null || true
    done
    
    # Compile and install the policy
    if checkmodule -M -m -o /tmp/k8s_custom_policies.mod /tmp/k8s_custom_policies.te >> /var/log/k8s-selinux.log 2>&1; then
        if semodule_package -o /tmp/k8s_custom_policies.pp -m /tmp/k8s_custom_policies.mod >> /var/log/k8s-selinux.log 2>&1; then
            if semodule -i /tmp/k8s_custom_policies.pp >> /var/log/k8s-selinux.log 2>&1; then
                echo "[$(date)] SELinux policy applied successfully" >> /var/log/k8s-selinux.log
                # Disable dontaudit rules to make SELinux less restrictive and show all denials
                semodule -DB >> /var/log/k8s-selinux.log 2>&1
                echo "[$(date)] Disabled dontaudit rules for better visibility" >> /var/log/k8s-selinux.log
                rm -f /tmp/k8s_custom_policies.{te,mod,pp}
                exit 0
            fi
        fi
    fi
    echo "[$(date)] Failed to apply SELinux policy" >> /var/log/k8s-selinux.log
    exit 1
- path: /etc/systemd/system/k8s-selinux-policy.service
  permissions: '0644'
  content: |
    [Unit]
    Description=Apply K8s SELinux Policy for Leap Micro
    DefaultDependencies=no
    After=local-fs.target
    Before=k3s.service network-pre.target
    
    [Service]
    Type=oneshot
    RemainAfterExit=yes
    ExecStart=/usr/local/bin/apply-k8s-selinux-policy.sh
    
    [Install]
    WantedBy=sysinit.target
%{ endif ~}

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

# Allow root SSH login (needed for LeapMicro)
disable_root: false
ssh_pwauth: false

# Resize /var, not /, as that's the last partition in MicroOS image.
growpart:
    devices: ["/var"]

# Make sure the hostname is set correctly
hostname: ${hostname}
preserve_hostname: true

runcmd:

${cloudinit_runcmd_common}

%{ if os == "leapmicro" ~}
# Enable and run SELinux policy service
- systemctl daemon-reload
- systemctl enable k8s-selinux-policy.service
- systemctl start k8s-selinux-policy.service
%{ endif ~}

%{ if os == "microos" ~}
# Apply SELinux policies for k8s on MicroOS (keeping old approach for now)
- |
  if command -v checkmodule >/dev/null 2>&1 && command -v semodule_package >/dev/null 2>&1 && command -v semodule >/dev/null 2>&1; then
    echo "Setting up SELinux policies for Kubernetes..."
    
    # Create the policy file
    cat > /tmp/k8s_custom_policies.te <<'SELINUX_POLICY'
  module k8s_custom_policies 1.0;
  
  require {
      type container_t;
      type cert_t;
      type proc_t;
      type sysfs_t;
      type unreserved_port_t;
      type kubernetes_port_t;
      type http_port_t;
      type hplip_port_t;
      type node_t;
      class dir { read search open getattr };
      class file { read open getattr };
      class lnk_file { read getattr };
      class tcp_socket { name_bind name_connect accept listen };
      class node { tcp_recv tcp_send };
      class peer recv;
      class filesystem getattr;
  }
  
  # Allow containers to read certificate directories and files
  allow container_t cert_t:dir { read search open getattr };
  allow container_t cert_t:file { read open getattr };
  
  # Allow containers to read proc filesystem (needed for metrics-server filesystem collector)
  allow container_t proc_t:file { read open getattr };
  allow container_t proc_t:dir { read search open getattr };
  allow container_t proc_t:lnk_file { read getattr };
  allow container_t proc_t:filesystem getattr;
  
  # Also allow sysfs access which is often needed alongside proc
  allow container_t sysfs_t:file { read open getattr };
  allow container_t sysfs_t:dir { read search open getattr };
  allow container_t sysfs_t:lnk_file { read getattr };
  allow container_t sysfs_t:filesystem getattr;
  
  # Allow containers to bind to kubernetes ports (including 10250 for metrics-server)
  allow container_t kubernetes_port_t:tcp_socket { name_bind name_connect accept listen };
  
  # Allow containers to bind to hplip ports (including 9100 for node-exporter)
  allow container_t hplip_port_t:tcp_socket { name_bind name_connect accept listen };
  
  # Allow containers to bind to unreserved high ports
  allow container_t unreserved_port_t:tcp_socket { name_bind name_connect accept listen };
  
  # Allow containers to bind to http ports (some exporters may use these)
  allow container_t http_port_t:tcp_socket { name_bind name_connect accept listen };
  
  # Allow container-to-container communication (needed for readiness probes)
  allow container_t container_t:tcp_socket { name_connect accept };
  allow container_t container_t:peer recv;
  
  # Allow containers to use network nodes
  allow container_t node_t:node { tcp_recv tcp_send };
  SELINUX_POLICY
    
    echo "Compiling and applying SELinux policies..."
    checkmodule -M -m -o /tmp/k8s_custom_policies.mod /tmp/k8s_custom_policies.te && \
    semodule_package -o /tmp/k8s_custom_policies.pp -m /tmp/k8s_custom_policies.mod && \
    semodule -i /tmp/k8s_custom_policies.pp && \
    rm -f /tmp/k8s_custom_policies.{te,mod,pp} && \
    echo "Custom SELinux policies applied successfully" || \
    echo "Warning: Could not apply custom SELinux policies"
  else
    echo "SELinux policy tools not available, skipping custom policies"
  fi
%{ endif ~}

# Configure default routes based on public ip availability
%{if private_network_only~}
# Private-only setup: eth0 is the private interface
- [ip, route, add, default, via, '${network_gw_ipv4}', dev, 'eth0', metric, '100']
%{else~}
# Standard setup: eth0 is public, configure both IPv4 and IPv6
- "ip route add default via 172.31.1.1 dev eth0 metric 100 2>/dev/null || true"
- "ip -6 route add default via fe80::1 dev eth0 metric 100 2>/dev/null || true"
%{endif~}

%{if swap_size != ""~}
- |
  btrfs subvolume create /var/lib/swap
  chmod 700 /var/lib/swap
  truncate -s 0 /var/lib/swap/swapfile
  chattr +C /var/lib/swap/swapfile
  fallocate -l ${swap_size} /var/lib/swap/swapfile
  chmod 600 /var/lib/swap/swapfile
  mkswap /var/lib/swap/swapfile
  swapon /var/lib/swap/swapfile
  echo "/var/lib/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
  cat << EOF >> /etc/systemd/system/swapon-late.service
  [Unit]
  Description=Activate all swap devices later
  After=default.target

  [Service]
  Type=oneshot
  ExecStart=/sbin/swapon -a

  [Install]
  WantedBy=default.target
  EOF
  systemctl daemon-reload
  systemctl enable swapon-late.service
%{endif~}
