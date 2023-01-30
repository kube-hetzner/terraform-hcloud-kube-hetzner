data "hcloud_image" "microos_image" {
  with_selector = "microos-snapshot=yes,creator_id=${null_resource.packer.id}"
  most_recent   = true
}

resource "null_resource" "packer" {
  triggers = {
    file_changed = md5(file("${path.module}/packer/hcloud-microos-snapshot.pkr.hcl"))
  }

  provisioner "local-exec" {
    # working_dir = "./packer"
    # credits for packer integration to https://austincloud.guru/2020/02/27/building-packer-image-with-terraform/
    command = <<EOF
RED='\033[0;31m'   # Red Text
GREEN='\033[0;32m' # Green Text
BLUE='\033[0;34m'  # Blue Text
NC='\033[0m'       # No Color

packer build -force \
  -var hcloud_token=${var.hcloud_token} \
  -var opensuse_microos_mirror_link=${var.opensuse_microos_mirror_link} \
  -var creator_id=${self.id} \
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
