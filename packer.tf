locals {
    packages = length(local.packages_to_install) > 0 ? "-var packages_to_install=${local.packages_to_install}"  : ""
}
data "hcloud_image" "microos_image" {
  with_selector = "microos-snapshot=yes,creator_id=${null_resource.packer.id}"
  most_recent   = true
}

resource "null_resource" "packer" {
  triggers = {
    file_changed = md5(file("${path.module}/packer/hcloud-microos-snapshot.pkr.hcl"))
  }

  provisioner "local-exec" {
    environment = {
      HCLOUD_TOKEN = nonsensitive(var.hcloud_token)
    }

    # credits for packer integration to https://austincloud.guru/2020/02/27/building-packer-image-with-terraform/
    command = <<EOF
RED='\033[0;31m'   # Red Text
GREEN='\033[0;32m' # Green Text
BLUE='\033[0;34m'  # Blue Text
NC='\033[0m'       # No Color

packer build -force \
  -var opensuse_microos_mirror_link=${var.opensuse_microos_mirror_link} \
  -var creator_id=${self.id} ${local.packages} \
  ${path.module}/packer/hcloud-microos-snapshot.pkr.hcl

if [ $? -eq 0 ]; then
  printf "\n $GREEN Packer Succeeded $NC \n"
else
  printf "\n $RED Packer Failed $NC \n" >&2
  exit 1
fi
EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Packer image will not be destroyed yet...'"
  }
}
