locals {
  first_control_plane_network_ip = cidrhost(hcloud_network.k3s.ip_range, 2)
  ssh_public_key                 = trimspace(file(var.public_key))
  hcloud_image_name              = "ubuntu-20.04"

  k3os_install_commands = [
    "apt install -y grub-efi grub-pc-bin mtools xorriso",
    "latest=$(curl -s https://api.github.com/repos/rancher/k3os/releases | jq '.[0].tag_name')",
    "curl -Lo ./install.sh https://raw.githubusercontent.com/rancher/k3os/$(echo $latest | xargs)/install.sh",
    "chmod +x ./install.sh",
    "./install.sh --config /tmp/config.yaml /dev/sda https://github.com/rancher/k3os/releases/download/$(echo $latest | xargs)/k3os-amd64.iso",
    "shutdown -r +1",
    "sleep 3",
    "exit 0"
  ]
}
