/*
 * Creates a MicroOS snapshot for Hetzner Cloud
 */

variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}

# We download OpenSUSE MicroOS from an automatically selected mirror. In case it somehow does not work for you (you get a 403), you can try other mirrors.
# You can find a working mirror at https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2.mirrorlist
variable "opensuse_microos_mirror_link" {
  type    = string
  default = "https://ftp.gwdg.de/pub/opensuse/repositories/devel:/kubic:/images/openSUSE_Tumbleweed/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2"
}

# If you need to add other packages to the OS, do it here in the default value, like ["vim", "curl", "wget"]
# When looking for packages, you need to search for OpenSUSE Tumbleweed packages, as MicroOS is based on Tumbleweed.
variable "packages_to_install" {
  type    = list(string)
  default = []
}

locals {
  needed_packages = join(" ", concat(["restorecond policycoreutils policycoreutils-python-utils setools-console bind-utils wireguard-tools open-iscsi nfs-client xfsprogs cryptsetup lvm2 git"], var.packages_to_install))
}

source "hcloud" "microos-snapshot" {
  image       = "ubuntu-20.04"
  rescue      = "linux64"
  location    = "nbg1"
  server_type = "cpx11" # at least a disk size of >= 40GiB is needed to install the MicroOS image
  snapshot_labels = {
    microos-snapshot = "yes"
    creator          = "kube-hetzner"
  }
  snapshot_name = "OpenSUSE MicroOS by Kube-Hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

build {
  sources = ["source.hcloud.microos-snapshot"]

  # Download the MicroOS image and write it to disk
  provisioner "shell" {
    inline = [
      "sleep 5",
      "wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only ${var.opensuse_microos_mirror_link}",
      "echo 'MicroOS image loaded, writing to disk... '",
      "qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda",
      "echo 'done. Rebooting...'",
      "sleep 2; reboot"
    ]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline = [<<-EOT
      set -ex
      echo "First reboot successful, updating and needed package..."
      transactional-update shell <<< "zypper --no-gpg-checks --non-interactive install https://github.com/k3s-io/k3s-selinux/releases/download/v1.3.testing.4/k3s-selinux-1.3-4.sle.noarch.rpm"
      transactional-update --continue shell <<< "zypper addlock k3s-selinux"
      transactional-update --continue shell <<< "zypper --gpg-auto-import-keys install -y ${local.needed_packages}"
      sleep 1 && udevadm settle && reboot
      EOT
    ]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS and do house-keeping
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
