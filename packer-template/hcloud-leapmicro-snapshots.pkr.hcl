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

  needed_packages = join(" ", concat([
    # SELinux packages
    "container-selinux",
    "policycoreutils",
    "policycoreutils-python-utils",
    "policycoreutils-devel",
    "checkpolicy",
    "selinux-policy",
    "selinux-policy-devel",
    "selinux-tools",
    # Container and storage packages
    "fuse-overlayfs",
    "xfsprogs",
    "cryptsetup",
    # System packages
    "audit",
    # Additional tools
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
    transactional-update shell <<- EOF
    setenforce 0

    # Fix the main repository URL if it's using cdn.opensuse.org
    ARCH=\$(uname -m)
    if [ "\$ARCH" = "aarch64" ]; then
      zypper mr --url="https://download.opensuse.org/distribution/leap-micro/6.1/product/repo/openSUSE-Leap-Micro-6.1-aarch64/" repo-main || true
    else
      zypper mr --url="https://download.opensuse.org/distribution/leap-micro/6.1/product/repo/openSUSE-Leap-Micro-6.1-x86_64/" repo-main || true
    fi

    # Add additional repositories for missing packages
    zypper addrepo -G -f https://download.opensuse.org/distribution/leap/${var.leap_version}/repo/oss/ leap-${var.leap_version}-oss || true
    zypper addrepo -G -f https://download.opensuse.org/update/leap/${var.leap_version}/oss/ leap-${var.leap_version}-update || true

    zypper --non-interactive --gpg-auto-import-keys refresh || true

    # Install packages - some may already be installed or not available
    zypper --verbose --non-interactive install --allow-vendor-change --no-recommends ${local.needed_packages} || true

    # Try to install additional packages from Leap repos
    zypper --verbose --non-interactive install --allow-vendor-change --no-recommends git bash-completion nfs-utils cifs-utils open-iscsi || true

    rpm --import https://rpm.rancher.io/public.key
    zypper --verbose --non-interactive install -y https://github.com/k3s-io/k3s-selinux/releases/download/${var.k3s_selinux_version}/k3s-selinux-${replace(replace(var.k3s_selinux_version, "v", ""), ".stable.1", "")}-1.slemicro.noarch.rpm
    zypper addlock k3s-selinux

    restorecon -Rv /etc/selinux/targeted/policy
    restorecon -Rv /var/lib
    fixfiles restore
    touch /.autorelabel
    
    # Create SELinux policy to allow containers to read certificate directories
    # This addresses cluster-autoscaler and other k8s components needing cert access
    cat > /tmp/k8s-custom-policies.te <<'SELINUX_POLICY'
module k8s-custom-policies 1.0;

require {
    type container_t;
    type cert_t;
    type fail2ban_t;
    type net_conf_t;
    type unreserved_port_t;
    class dir read;
    class file { read open getattr };
    class sock_file create;
    class tcp_socket { name_bind name_connect };
}

# Allow containers to read certificate directories and files
allow container_t cert_t:dir read;
allow container_t cert_t:file { read open getattr };

# Allow fail2ban to create socket files in /etc (net_conf_t context)
allow fail2ban_t net_conf_t:sock_file create;

# Allow containers to bind to high ports (including 10250 for metrics-server)
allow container_t unreserved_port_t:tcp_socket { name_bind name_connect };
SELINUX_POLICY
    
    # Compile and install the SELinux policy module
    checkmodule -M -m -o /tmp/k8s-custom-policies.mod /tmp/k8s-custom-policies.te || true
    semodule_package -o /tmp/k8s-custom-policies.pp -m /tmp/k8s-custom-policies.mod || true
    semodule -i /tmp/k8s-custom-policies.pp || true
    
    # Clean up temporary files
    rm -f /tmp/k8s-custom-policies.{te,mod,pp}

    echo so what do we have here
    rpm -qa |grep container
    zypper search-packages -s container-selinux

    # update all packages
    zypper update -y

    sed -i '/disable_root/c\disable_root: false' /etc/cloud/cloud.cfg
    sed -i '/keys_to_console/s/^/#/' /etc/cloud/cloud.cfg
    sed -i '/^#*PermitRootLogin/s/.*/PermitRootLogin yes/' /etc/ssh/ssh_config.d/50-suse.conf
    setenforce 1
    EOF
    sleep 10 && udevadm settle && reboot
  EOT

  install_fail2ban = <<-EOT
    transactional-update shell <<- EOF
    # Check if git is available (should have been installed in previous step)
    if ! command -v git >/dev/null 2>&1; then
      echo "Git not found, trying to install it..."
      zypper --non-interactive --gpg-auto-import-keys refresh || true
      zypper --verbose --non-interactive install --allow-vendor-change git || true
    fi

    # Install fail2ban from source
    if command -v git >/dev/null 2>&1; then
      cd /tmp
      git clone --branch ${var.fail2ban_version} --depth 1 https://github.com/fail2ban/fail2ban.git
      cd fail2ban
      python3 setup.py install --without-tests
      cp build/fail2ban.service /etc/systemd/system/
      systemctl enable fail2ban.service
      cd /
      rm -rf /tmp/fail2ban
      echo "fail2ban installed successfully from source"
    else
      echo "ERROR: Cannot install fail2ban - git is not available"
      exit 1
    fi
    EOF
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
