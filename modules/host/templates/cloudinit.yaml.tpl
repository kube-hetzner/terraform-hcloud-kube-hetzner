#cloud-config

debug: True

write_files:

${cloudinit_write_files_common}

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

# Resize /var, not /, as that's the last partition in MicroOS image.
growpart:
    devices: ["/var"]

# Make sure the hostname is set correctly
hostname: ${hostname}
preserve_hostname: true

runcmd:

${cloudinit_runcmd_common}

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
