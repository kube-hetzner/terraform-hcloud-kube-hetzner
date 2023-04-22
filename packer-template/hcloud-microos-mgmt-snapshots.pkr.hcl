/*
 * Creates a MicroOS snapshot for Kube-Hetzner
 */

variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}

variable "headscale_version" {
  type    = string
  default = "0.22.1"
}

# We download the OpenSUSE MicroOS x86 image from an automatically selected mirror. In case it somehow does not work for you (you get a 403), you can try other mirrors.
# You can find a working mirror at https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2.mirrorlist
variable "opensuse_microos_x86_mirror_link" {
  type    = string
  default = "https://ftp.gwdg.de/pub/opensuse/repositories/devel:/kubic:/images/openSUSE_Tumbleweed/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2"
}

# We download the OpenSUSE MicroOS ARM image from an automatically selected mirror. In case it somehow does not work for you (you get a 403), you can try other mirrors.
# You can find a working mirror at https://download.opensuse.org/ports/aarch64/tumbleweed/appliances/openSUSE-MicroOS.aarch64-OpenStack-Cloud.qcow2.mirrorlist
variable "opensuse_microos_arm_mirror_link" {
  type    = string
  default = "https://ftp.gwdg.de/pub/opensuse/ports/aarch64/tumbleweed/appliances/openSUSE-MicroOS.aarch64-OpenStack-Cloud.qcow2"
}

# If you need to add other packages to the OS, do it here in the default value, like ["vim", "curl", "wget"]
# When looking for packages, you need to search for OpenSUSE Tumbleweed packages, as MicroOS is based on Tumbleweed.
variable "packages_to_install" {
  type    = list(string)
  default = []
}

locals {
  needed_packages = join(" ", concat(["restorecond policycoreutils policycoreutils-python-utils setools-console bind-utils wireguard-tools dpkg"], var.packages_to_install))

  # Add local variables for inline shell commands
  download_image = "wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only "

  write_image = <<-EOT
    set -ex
    echo 'MicroOS image loaded, writing to disk... '
    qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda
    echo 'done. Rebooting...'
    sleep 1 && udevadm settle && reboot
  EOT

  install_packages = <<-EOT
    set -ex
    echo "First reboot successful, installing needed packages..."
    transactional-update shell <<< "setenforce 0"
    transactional-update --continue shell <<< "zypper --gpg-auto-import-keys install -y ${local.needed_packages}"
    # Headscale setup, see https://github.com/juanfont/headscale/blob/main/docs/running-headscale-linux.md
    transactional-update --continue shell <<< "wget --output-document=headscale.deb https://github.com/juanfont/headscale/releases/download/v${var.headscale_version}/headscale_${var.headscale_version}_linux_$([ \"$(uname -m)\" == \"x86_64\" ] && echo \"amd64\" || echo \"arm64\").deb"
    transactional-update --continue shell <<< "sudo dpkg --install headscale.deb"
    transactional-update --continue shell <<< "sudo systemctl enable headscale"
    transactional-update --continue shell <<< "restorecon -Rv /etc/selinux/targeted/policy && restorecon -Rv /var/lib && setenforce 1"
    sleep 1 && udevadm settle && reboot
  EOT

  clean_up = <<-EOT
    set -ex
    echo "Second reboot successful, cleaning-up..."
    rm -rf /etc/ssh/ssh_host_*
    sleep 1 && udevadm settle
  EOT
}

# Source for the MicroOS x86 snapshot
source "hcloud" "microos-x86-snapshot-management" {
  image       = "ubuntu-22.04"
  rescue      = "linux64"
  location    = "fsn1"
  server_type = "cpx11" # disk size of >= 40GiB is needed to install the MicroOS image
  snapshot_labels = {
    microos-snapshot = "yes"
    type             = "management"
    creator          = "kube-hetzner"
  }
  snapshot_name = "OpenSUSE MicroOS x86 Management by Kube-Hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

# Source for the MicroOS ARM snapshot
source "hcloud" "microos-arm-snapshot-management" {
  image       = "ubuntu-22.04"
  rescue      = "linux64"
  location    = "fsn1"
  server_type = "cax11" # disk size of >= 40GiB is needed to install the MicroOS image
  snapshot_labels = {
    microos-snapshot = "yes"
    type             = "management"
    creator          = "kube-hetzner"
  }
  snapshot_name = "OpenSUSE MicroOS ARM Management by Kube-Hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

# Build the MicroOS x86 snapshot
build {
  sources = ["source.hcloud.microos-x86-snapshot-management"]

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
  sources = ["source.hcloud.microos-arm-snapshot-management"]

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
