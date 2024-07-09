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

%{if swap_size != ""~}
- |
  transactional-update --continue shell <<- EOF
    fallocate -l ${swap_size} /var/swapfile
    chmod 600 /var/swapfile
    mkswap /var/swapfile
    swapon /var/swapfile
    echo '/var/swapfile swap swap defaults 0 0' >> /etc/fstab
  EOF
%{endif~}
