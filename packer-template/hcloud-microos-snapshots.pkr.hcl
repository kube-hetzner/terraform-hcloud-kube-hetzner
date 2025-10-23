/*
 * Creates a MicroOS snapshot for Kube-Hetzner
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

# We download the OpenSUSE MicroOS x86 image from an automatically selected mirror.
variable "opensuse_microos_x86_mirror_link" {
  type    = string
  default = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-ContainerHost-OpenStack-Cloud.qcow2"
}

# We download the OpenSUSE MicroOS ARM image from an automatically selected mirror.
variable "opensuse_microos_arm_mirror_link" {
  type    = string
  default = "https://download.opensuse.org/ports/aarch64/tumbleweed/appliances/openSUSE-MicroOS.aarch64-ContainerHost-OpenStack-Cloud.qcow2"
}

# If you need to add other packages to the OS, do it here in the default value, like ["vim", "curl", "wget"]
# When looking for packages, you need to search for OpenSUSE Tumbleweed packages, as MicroOS is based on Tumbleweed.
variable "packages_to_install" {
  type    = list(string)
  default = []
}

variable "include_aws_ecr_credential_provider" {
  description = "Enable to include the aws cli package and the ecr-credential-provider binary"
  type        = bool
  default     = false
}

locals {
  required_packages = ["restorecond", "policycoreutils", "policycoreutils-python-utils", "setools-console", "audit", "bind-utils", "wireguard-tools", "fuse", "open-iscsi", "nfs-client", "xfsprogs", "cryptsetup", "lvm2", "git", "cifs-utils", "bash-completion", "mtr", "tcpdump", "udica", "qemu-guest-agent"]

  optional_packages = concat(
    var.include_aws_ecr_credential_provider ? ["aws-cli"] : []
  )

  final_package_list = join(" ", concat(local.required_packages, local.optional_packages, var.packages_to_install))

  # Add local variables for inline shell commands
  download_image = "wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only "

  write_image = <<-EOT
    set -ex
    echo 'MicroOS image loaded, writing to disk... '
    qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda
    echo 'done. Rebooting...'
    sleep 1 && udevadm settle && reboot
  EOT

  install_aws_ecr_credential_provider_commands = <<-EOT
    transactional-update --continue pkg install -y go make
    transactional-update --continue shell <<- EOF
    setenforce 0
    mkdir -p /tmp/cloud-provider-aws
    cd /tmp/cloud-provider-aws
    git clone --depth=1 --branch v1.34.1 https://github.com/kubernetes/cloud-provider-aws build
    (export GOPATH=/tmp/cloud-provider-aws/go && export GOCACHE=/tmp/cloud-provider-aws/go_cache && cd build/cmd/ecr-credential-provider && go build)
    mkdir -p /opt/kubernetes-credential-provider/bin
    cp build/cmd/ecr-credential-provider/ecr-credential-provider /opt/kubernetes-credential-provider/bin
    rm -rf /tmp/cloud-provider-aws
    setenforce 1
    EOF
    transactional-update --continue pkg rm --clean-deps -y go make
  EOT

  install_packages = <<-EOT
    set -ex
    echo "First reboot successful, installing needed packages..."
    transactional-update --continue pkg install -y ${local.final_package_list}
    transactional-update --continue shell <<- EOF
    setenforce 0
    rpm --import https://rpm.rancher.io/public.key
    zypper install -y https://github.com/k3s-io/k3s-selinux/releases/download/v1.6.stable.1/k3s-selinux-1.6-1.sle.noarch.rpm
    zypper addlock k3s-selinux
    restorecon -Rv /etc/selinux/targeted/policy
    restorecon -Rv /var/lib
    setenforce 1
    EOF
    ${var.include_aws_ecr_credential_provider ? local.install_aws_ecr_credential_provider_commands:""}
    transactional-update --continue shell <<- EOF
    zypper cc -a
    EOF
    sleep 1 && udevadm settle && reboot
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

# Source for the MicroOS x86 snapshot
source "hcloud" "microos-x86-snapshot" {
  image       = "ubuntu-24.04"
  rescue      = "linux64"
  location    = "fsn1"
  server_type = "cx22" # disk size of >= 40GiB is needed to install the MicroOS image
  snapshot_labels = {
    microos-snapshot = "yes"
    creator          = "kube-hetzner"
  }
  snapshot_name = "OpenSUSE MicroOS x86 by Kube-Hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

# Source for the MicroOS ARM snapshot
source "hcloud" "microos-arm-snapshot" {
  image       = "ubuntu-24.04"
  rescue      = "linux64"
  location    = "fsn1"
  server_type = "cax11" # disk size of >= 40GiB is needed to install the MicroOS image
  snapshot_labels = {
    microos-snapshot = "yes"
    creator          = "kube-hetzner"
  }
  snapshot_name = "OpenSUSE MicroOS ARM by Kube-Hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

# Build the MicroOS x86 snapshot
build {
  sources = ["source.hcloud.microos-x86-snapshot"]

  # Download the MicroOS x86 image
  provisioner "shell" {
    inline = ["${local.download_image}${var.opensuse_microos_x86_mirror_link}"]
  }

  # Write the MicroOS x86 image to disk
  provisioner "shell" {
    inline            = [local.write_image]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS x86 and do house-keeping
  provisioner "shell" {
    pause_before      = "5s"
    inline            = [local.install_packages]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS x86 and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline       = [local.clean_up]
  }
}

# Build the MicroOS ARM snapshot
build {
  sources = ["source.hcloud.microos-arm-snapshot"]

  # Download the MicroOS ARM image
  provisioner "shell" {
    inline = ["${local.download_image}${var.opensuse_microos_arm_mirror_link}"]
  }

  # Write the MicroOS ARM image to disk
  provisioner "shell" {
    inline            = [local.write_image]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS ARM and do house-keeping
  provisioner "shell" {
    pause_before      = "5s"
    inline            = [local.install_packages]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS ARM and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline       = [local.clean_up]
  }
}
