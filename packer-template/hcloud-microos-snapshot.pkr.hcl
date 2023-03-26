/*
 * Creates a MicroOS snapshot for Hetzner Cloud
 */

variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}

variable "opensuse_microos_mirror_link" {
  type    = string
  default = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2"
}

locals {
  needed_packages = ["restorecond policycoreutils policycoreutils-python-utils setools-console bind-utils"]
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
      echo First reboot successful, updating and installing basic packages...
      # Update to latest MicroOS version
      transactional-update dup
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
      echo Second reboot successful, cleaning-up...
      transactional-update cleanup
      rm -rf /var/log/*
      rm -rf /etc/ssh/ssh_host_*
      sleep 1 && udevadm settle
      EOT
    ]
  }

}
