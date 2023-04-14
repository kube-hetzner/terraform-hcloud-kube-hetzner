/*
 * Creates a MicroOS snapshot for Hetzner Cloud
 */

variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}

# We download OpenSUSE MicroOS x86 from an automatically selected mirror. In case it somehow does not work for you (you get a 403), you can try other mirrors.
# You can find a working mirror at https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2.mirrorlist
variable "opensuse_microos_x86_mirror_link" {
  type    = string
  default = "https://ftp.gwdg.de/pub/opensuse/repositories/devel:/kubic:/images/openSUSE_Tumbleweed/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2"
}

# We download OpenSUSE MicroOS aarch64 from an automatically selected mirror. In case it somehow does not work for you (you get a 403), you can try other mirrors.
# You can find a working mirror at https://download.opensuse.org/ports/aarch64/tumbleweed/appliances/openSUSE-MicroOS.aarch64-OpenStack-Cloud.qcow2.mirrorlist
variable "opensuse_microos_aarch64_mirror_link" {
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
  needed_packages = join(" ", concat(["restorecond policycoreutils policycoreutils-python-utils setools-console bind-utils wireguard-tools open-iscsi nfs-client xfsprogs cryptsetup lvm2 git cifs-utils"], var.packages_to_install))
}

source "hcloud" "microos-x86-snapshot" {
  image       = "ubuntu-22.04"
  rescue      = "linux64"
  location    = "fsn1"
  server_type = "cpx11" # disk size of >= 40GiB is needed to install the MicroOS image
  snapshot_labels = {
    microos-snapshot = "x86"
    creator          = "kube-hetzner"
  }
  snapshot_name = "OpenSUSE MicroOS x86 by Kube-Hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

source "hcloud" "microos-aarch64-snapshot" {
  image       = "ubuntu-22.04"
  rescue      = "linux64"
  location    = "fsn1"
  server_type = "cax11" # disk size of >= 40GiB is needed to install the MicroOS image
  snapshot_labels = {
    microos-snapshot = "aarch64"
    creator          = "kube-hetzner"
  }
  snapshot_name = "OpenSUSE MicroOS aarch64 by Kube-Hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

build {
  sources = ["source.hcloud.microos-x86-snapshot"]

  # Download the MicroOS x86 image and write it to disk
  provisioner "shell" {
    inline = [<<-EOT
      set -ex
      wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only ${var.opensuse_microos_x86_mirror_link}
      echo 'MicroOS x86 image loaded, writing to disk... '
      qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda
      echo 'done. Rebooting...'
      sleep 1 && udevadm settle && reboot
      EOT
      ]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS x86 and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline = [<<-EOT
      set -ex
      echo "First reboot successful, installing needed packages..."
      transactional-update shell <<< "setenforce 0"
      transactional-update --continue shell <<< "zypper --gpg-auto-import-keys install -y ${local.needed_packages}"
      transactional-update --continue shell <<< "rpm --import https://rpm-testing.rancher.io/public.key"
      transactional-update --continue shell <<< "zypper --no-gpg-checks --non-interactive install https://github.com/k3s-io/k3s-selinux/releases/download/v1.3.testing.4/k3s-selinux-1.3-4.sle.noarch.rpm"
      transactional-update --continue shell <<< "zypper addlock k3s-selinux"
      transactional-update --continue shell <<< "restorecon -Rv /etc/selinux/targeted/policy && restorecon -Rv /var/lib && setenforce 1"
      sleep 1 && udevadm settle && reboot
      EOT
    ]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS x86 and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline = [<<-EOT
      set -ex
      echo "Second reboot successful, cleaning-up..."
      rm -rf /etc/ssh/ssh_host_*
      sleep 1 && udevadm settle
      EOT
    ]
  }
}

build {
  sources = ["source.hcloud.microos-aarch64-snapshot"]

  # Download the MicroOS aarch64 image and write it to disk
  provisioner "shell" {
    inline = [<<-EOT
      set -ex
      wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only ${var.opensuse_microos_aarch64_mirror_link}
      echo 'MicroOS aarch64 image loaded, writing to disk... '
      qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda
      echo 'done. Rebooting...'
      sleep 1 && udevadm settle && reboot
      EOT
      ]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS aarch64 and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline = [<<-EOT
      set -ex
      echo "First reboot successful, installing needed packages..."
      transactional-update shell <<< "setenforce 0"
      transactional-update --continue shell <<< "zypper --gpg-auto-import-keys install -y ${local.needed_packages}"
      transactional-update --continue shell <<< "rpm --import https://rpm-testing.rancher.io/public.key"
      transactional-update --continue shell <<< "zypper --no-gpg-checks --non-interactive install https://github.com/k3s-io/k3s-selinux/releases/download/v1.3.testing.4/k3s-selinux-1.3-4.sle.noarch.rpm"
      transactional-update --continue shell <<< "zypper addlock k3s-selinux"
      transactional-update --continue shell <<< "restorecon -Rv /etc/selinux/targeted/policy && restorecon -Rv /var/lib && setenforce 1"
      sleep 1 && udevadm settle && reboot
      EOT
    ]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS aarch64 and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline = [<<-EOT
      set -ex
      echo "Second reboot successful, cleaning-up..."
      rm -rf /etc/ssh/ssh_host_*
      sleep 1 && udevadm settle
      EOT
    ]
  }
}