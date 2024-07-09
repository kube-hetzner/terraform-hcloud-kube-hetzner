#cloud-config

debug: True

write_files:

${cloudinit_write_files_common}

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

# See https://en.opensuse.org/SDB:Partitioning#Creating_a_btrfs_swapfile
# And https://en.opensuse.org/openSUSE:Snapper_Tutorial#Swapfile
# according to https://btrfs.readthedocs.io/en/latest/Swapfile.html we need to somehow run swapon -a after reboot
# Due to some `swapon: /var/lib/swap/swapfile: swapon failed: Read-only file system`
# I use separate systemd script
%{if swap_size != ""~}
- |
  btrfs subvolume create /var/lib/swap
  chmod 700 /var/lib/swap
  truncate -s 0 /var/lib/swap/swapfile
  chattr +C /var/lib/swap/swapfile
  fallocate -l 4G /var/lib/swap/swapfile
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
