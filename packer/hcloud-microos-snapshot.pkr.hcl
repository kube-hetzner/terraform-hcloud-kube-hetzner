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
  default = "https://ftp.gwdg.de/pub/opensuse/repositories/devel:/kubic:/images/openSUSE_Tumbleweed/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2"
}

variable "creator_id" {
  type    = string
  default = "123456789"
}

source "hcloud" "microos-snapshot" {
  image       = "ubuntu-20.04"
  rescue      = "linux64"
  location    = "nbg1"
  server_type = "cx21" # at least a disk size of >= 40GiB is needed to install MicroOS image
  snapshot_labels = {
    microos-snapshot = "yes"
    creator          = "kube-hetzner"
    creator_id       = var.creator_id
  }
  snapshot_name = "MicroOS snapshot created by kube-hetzner"
  ssh_username  = "root"
  token         = var.hcloud_token
}

build {
  sources = ["source.hcloud.microos-snapshot"]

  # Download the MicroOS image and write it to disk
  provisioner "shell" {
    inline = [
      "sleep 5",
      "wget --timeout=5 ${var.opensuse_microos_mirror_link}",
      "qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda",
      "sleep 2; reboot"
    ]
    expect_disconnect = true
  }

  # Ensure connection to MicroOS and do house-keeping
  provisioner "shell" {
    pause_before = "5s"
    inline = [
      "echo Reboot successful, installing basic packages and cleaning-up....",
      "rm -rf /var/log/*"
    ]
  }
}
