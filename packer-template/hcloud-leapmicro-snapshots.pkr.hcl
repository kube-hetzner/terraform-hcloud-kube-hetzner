/*
 * Creates a Leap Micro snapshot for Kube-Hetzner
 */
packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.5"
      source  = "github.com/hashicorp/hcloud"
    }
  }
}

variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}

# We download the OpenSUSE Leap Micro x86 image from an automatically selected mirror.
variable "opensuse_leapmicro_x86_mirror_link" {
  type    = string
  default = "https://download.opensuse.org/distribution/leap-micro/6.1/appliances/openSUSE-Leap-Micro.x86_64-Base-qcow.qcow2"
}

# We download the OpenSUSE Leap Micro ARM image from an automatically selected mirror.
variable "opensuse_leapmicro_arm_mirror_link" {
  type    = string
  default = "https://download.opensuse.org/distribution/leap-micro/6.1/appliances/openSUSE-Leap-Micro.aarch64-Base-qcow.qcow2"
}

# If you need to add other packages to the OS, do it here in the default value, like ["vim", "curl", "wget"]
# When looking for packages, you need to search for OpenSUSE Tumbleweed packages, as Leap Micro is based on Tumbleweed.
variable "packages_to_install" {
  type    = list(string)
  default = []
}

locals {
  needed_packages = join(" ", concat([
    "busybox-bzip2",
    "container-selinux",
    "policycoreutils",
    "policycoreutils-devel",
    "policycoreutils-python-utils",
    "python3-policycoreutils",
    "python311-setools",
    "restorecond",
    "selinux-policy",
    "fuse-overlayfs",
    #"fuse",
    #"libfuse3",
    "audit",
    "open-iscsi",
    "nfs-client",
    "xfsprogs",
    "cryptsetup",
    "lvm2",
    "git",
    "cifs-utils",
    "bash-completion",
    "udica"
  ], var.packages_to_install))

  # Add local variables for inline shell commands
  download_image = "wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only "

  write_image = <<-EOT
    set -ex
    echo 'Leap Micro image loaded, writing to disk... '
    qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*leap-micro.*qcow2$') /dev/sda
    echo 'done. Rebooting...'
    sleep 1 && udevadm settle && reboot
  EOT

  install_packages = <<-EOT
    set -ex

    # echo "First reboot successful, installing needed packages..."
    ARCH=$(uname -m)
    REPO_URL="https://ftp.rz.uni-wuerzburg.de/opensuse/distribution/leap-micro/6.1/product/repo/openSUSE-Leap-Micro-6.1-$ARCH"
    transactional-update shell <<- EOF
    setenforce 0

    # Added mirror with higher prio.
    # As of now (23.04.2025), the main repo doesn't have container-selinux in vers. 2.236
    # thereforce, we prioritize the mirrors, as they seem to have the proper versions

    zypper ar "$REPO_URL" uni-wuerzburg-mirror
    zypper --non-interactive --gpg-auto-import-keys refresh

    zypper --verbose --non-interactive install --allow-vendor-change ${local.needed_packages}

    rpm --import https://rpm.rancher.io/public.key
    zypper --verbose --non-interactive install -y https://github.com/k3s-io/k3s-selinux/releases/download/v1.6.stable.1/k3s-selinux-1.6-1.slemicro.noarch.rpm
    zypper addlock k3s-selinux

    restorecon -Rv /etc/selinux/targeted/policy
    restorecon -Rv /var/lib
    fixfiles restore
    touch /.autorelabel

    echo so what do we have here
    rpm -qa |grep container
    zypper search-packages -s container-selinux

    sed -i '/disable_root/c\disable_root: false' /etc/cloud/cloud.cfg
    sed -i '/keys_to_console/s/^/#/' /etc/cloud/cloud.cfg
    sed -i '/^#*PermitRootLogin/s/.*/PermitRootLogin yes/' /etc/ssh/ssh_config.d/50-suse.conf
    setenforce 1
    EOF
    sleep 10 && udevadm settle && reboot
  EOT

  install_fail2ban = <<-EOT
    transactional-update shell <<- EOF
    git clone --branch 1.1.0 --depth 1 https://github.com/fail2ban/fail2ban.git
    cd fail2ban
    python3 setup.py install --without-tests
    cp build/fail2ban.service /etc/systemd/system/
    systemctl enable fail2ban.service
    EOF
  EOT

  clean_up = <<-EOT
    set -ex
    echo "Second reboot successful, cleaning-up..."
    rm -rf /etc/ssh/ssh_host_*
    echo "Make sure to use NetworkManager"
    touch /etc/NetworkManager/NetworkManager.conf
    sleep 1 && udevadm settle
  EOT
}

# Source for the Leap Micro x86 snapshot
source "hcloud" "leapmicro-x86-snapshot" {
  image       = "ubuntu-24.04"
  rescue      = "linux64"
  location    = "fsn1"
  server_type = "cpx21" # disk size of >= 40GiB is needed to install the Leap Micro image
  snapshot_labels = {
    leapmicro-snapshot = "yes"
    creator          = "kube-hetzner"
  }
  snapshot_name = "OpenSUSE Leap Micro x86 by Kube-Hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

# Source for the Leap Micro ARM snapshot
source "hcloud" "leapmicro-arm-snapshot" {
  image       = "ubuntu-24.04"
  rescue      = "linux64"
  location    = "fsn1"
  server_type = "cax21" # disk size of >= 40GiB is needed to install the Leap Micro image
  snapshot_labels = {
    leapmicro-snapshot = "yes"
    creator          = "kube-hetzner"
  }
  snapshot_name = "OpenSUSE Leap Micro ARM by Kube-Hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

# Build the Leap Micro x86 snapshot
build {
  sources = ["source.hcloud.leapmicro-x86-snapshot"]

  # Download the Leap Micro x86 image
  provisioner "shell" {
    inline = ["${local.download_image}${var.opensuse_leapmicro_x86_mirror_link}"]
  }

  # Write the Leap Micro x86 image to disk
  provisioner "shell" {
    inline            = [local.write_image]
    expect_disconnect = true
  }

  # Ensure connection to Leap Micro x86 and do house-keeping
  provisioner "shell" {
    pause_before      = "5s"
    inline            = [local.install_packages]
    expect_disconnect = true
  }

  # Install Fail2Ban
  # (Requires git; transactional-update makes reboot necessary, so handled in a separate step)
  provisioner "shell" {
    pause_before      = "5s"
    inline            = [local.install_fail2ban]
    expect_disconnect = true
  }

  # Ensure connection to Leap Micro x86 and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline       = [local.clean_up]
    expect_disconnect = true
  }
}

# Build the Leap Micro ARM snapshot
build {
  sources = ["source.hcloud.leapmicro-arm-snapshot"]

  # Download the Leap Micro ARM image
  provisioner "shell" {
    inline = ["${local.download_image}${var.opensuse_leapmicro_arm_mirror_link}"]
  }

  # Write the Leap Micro ARM image to disk
  provisioner "shell" {
    inline            = [local.write_image]
    expect_disconnect = true
  }

  # Ensure connection to Leap Micro ARM and do house-keeping
  provisioner "shell" {
    pause_before      = "5s"
    inline            = [local.install_packages]
    expect_disconnect = true
  }

  # Install Fail2Ban
  # (Requires git; transactional-update makes reboot necessary, so handled in a separate step)
  provisioner "shell" {
    pause_before      = "5s"
    inline            = [local.install_fail2ban]
    expect_disconnect = true
  }

  # Ensure connection to Leap Micro ARM and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline       = [local.clean_up]
  }
}
