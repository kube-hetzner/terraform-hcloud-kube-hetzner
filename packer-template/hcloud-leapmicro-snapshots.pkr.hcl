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

variable "k3s_selinux_version" {
  type        = string
  default     = "v1.6.stable.1"
  description = "k3s-selinux version to install"
}

variable "leap_micro_version" {
  type        = string
  default     = "6.1"
  description = "OpenSUSE Leap Micro version"
}

variable "fail2ban_version" {
  type        = string
  default     = "1.1.0"
  description = "fail2ban version to install"
}

variable "leap_version" {
  type        = string
  default     = "15.6"
  description = "OpenSUSE Leap version for additional repositories"
}

# We download the OpenSUSE Leap Micro x86 image from an automatically selected mirror.
variable "opensuse_leapmicro_x86_mirror_link" {
  type    = string
  default = ""
}

# We download the OpenSUSE Leap Micro ARM image from an automatically selected mirror.
variable "opensuse_leapmicro_arm_mirror_link" {
  type    = string
  default = ""
}

# If you need to add other packages to the OS, do it here in the default value, like ["vim", "curl", "wget"]
# When looking for packages, you need to search for OpenSUSE Tumbleweed packages, as Leap Micro is based on Tumbleweed.
variable "packages_to_install" {
  type    = list(string)
  default = []
}

locals {
  opensuse_leapmicro_x86_mirror_link_computed = var.opensuse_leapmicro_x86_mirror_link != "" ? var.opensuse_leapmicro_x86_mirror_link : "https://download.opensuse.org/distribution/leap-micro/${var.leap_micro_version}/appliances/openSUSE-Leap-Micro.x86_64-Base-qcow.qcow2"
  opensuse_leapmicro_arm_mirror_link_computed = var.opensuse_leapmicro_arm_mirror_link != "" ? var.opensuse_leapmicro_arm_mirror_link : "https://download.opensuse.org/distribution/leap-micro/${var.leap_micro_version}/appliances/openSUSE-Leap-Micro.aarch64-Base-qcow.qcow2"

  # Keep the package list minimal and working
  # SELinux tools will be installed via transactional-update
  needed_packages = join(" ", concat(["restorecond policycoreutils policycoreutils-python-utils audit open-iscsi nfs-client git selinux-policy xfsprogs cryptsetup lvm2 git bash-completion udica qemu-guest-agent bash-completion"], var.packages_to_install))

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
    echo "First reboot successful, installing needed packages..."

    # Add Rancher K3s repository for k3s-selinux (needs to be added to the system, not just in transactional environment)
    cat > /etc/zypp/repos.d/rancher-k3s-common.repo <<'REPO'
[rancher-k3s-common-stable]
name=Rancher K3s Common (stable)
baseurl=https://rpm.rancher.io/k3s/stable/common/microos/noarch
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://rpm.rancher.io/public.key
REPO

    # Import GPG key and make sure it's trusted
    curl -fsSL https://rpm.rancher.io/public.key > /tmp/rancher.key
    rpm --import /tmp/rancher.key || true
    
    # Refresh repositories with auto-import of keys
    zypper --non-interactive --gpg-auto-import-keys refresh || true

    # Install packages - first without k3s-selinux to ensure base packages are installed
    transactional-update --continue pkg install -y ${local.needed_packages}
    
    # Now install k3s-selinux with proper GPG handling inside transactional-update
    transactional-update --continue shell <<-'SHELL'
    set -ex
    # Import the key inside the transaction
    rpm --import https://rpm.rancher.io/public.key || true
    # Install k3s-selinux with no-gpg-checks as the key is already imported
    zypper --non-interactive --no-gpg-checks install -y k3s-selinux || {
      echo "Failed to install k3s-selinux via zypper, trying direct RPM download..."
      # Alternative: Download and install the RPM directly using the version variable
      # Strip the 'v' prefix from version for the RPM filename (e.g., v1.6.stable.1 -> 1.6.stable.1)
      K3S_SELINUX_RPM_VERSION=$(echo "${var.k3s_selinux_version}" | sed 's/^v//')
      curl -fsSL -o /tmp/k3s-selinux.rpm "https://github.com/k3s-io/k3s-selinux/releases/download/${var.k3s_selinux_version}/k3s-selinux-$${K3S_SELINUX_RPM_VERSION}-1.sle.noarch.rpm"
      rpm -i --nosignature /tmp/k3s-selinux.rpm || true
    }
    # Disable dontaudit rules to make SELinux less restrictive and show all denials
    echo "Disabling SELinux dontaudit rules for better visibility..."
    semodule -DB || true
SHELL
    sleep 1 && udevadm settle && reboot
  EOT

  install_fail2ban = <<-EOT
    set -ex
    echo "Installing fail2ban from source in transactional environment..."
    
    # Install fail2ban from source using transactional-update
    transactional-update --continue shell <<FAILBAN
    set -ex
    cd /tmp
    git clone --branch ${var.fail2ban_version} --depth 1 https://github.com/fail2ban/fail2ban.git
    cd fail2ban
    python3 setup.py install --without-tests
    cp build/fail2ban.service /etc/systemd/system/
    systemctl enable fail2ban.service
    cd /
    rm -rf /tmp/fail2ban
    echo "fail2ban installed successfully from source"
FAILBAN
    
    sleep 1 && udevadm settle && reboot
  EOT

  clean_up = <<-EOT
    set -ex
    echo "Second reboot successful, cleaning-up..."
    rm -rf /etc/ssh/ssh_host_*
    echo "Make sure to use NetworkManager"
    touch /etc/NetworkManager/NetworkManager.conf
    sleep 1 && udevadm settle
    echo "Running fstrim to reduce snapshot size..."
    fstrim -av || true
  EOT
}

# Source for the Leap Micro x86 snapshot
source "hcloud" "leapmicro-x86-snapshot" {
  image       = "ubuntu-24.04"
  rescue      = "linux64"
  location    = "fsn1"
  server_type = "cx22" # disk size of >= 40GiB is needed to install the Leap Micro image
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
  server_type = "cax11" # disk size of >= 40GiB is needed to install the Leap Micro image
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
    inline = ["${local.download_image}${local.opensuse_leapmicro_x86_mirror_link_computed}"]
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
    inline = ["${local.download_image}${local.opensuse_leapmicro_arm_mirror_link_computed}"]
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
