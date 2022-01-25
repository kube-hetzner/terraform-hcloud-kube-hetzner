locals {
  first_control_plane_network_ip = cidrhost(hcloud_network.k3s.ip_range, 2)
  hcloud_image_name              = "ubuntu-20.04"
  ssh_public_key                 = trimspace(file(var.public_key))
  # ssh_private_key is either the contents of var.private_key or null to use a ssh agent.
  ssh_private_key = var.private_key == null ? null : trimspace(file(var.private_key))
  # ssh_identity is not set if the private key is passed directly, but if ssh agent is used, the public key tells ssh agent which private key to use.
  # For terraforms provisioner.connection.agent_identity, we need the public key as a string.
  ssh_identity = var.private_key == null ? local.ssh_public_key : null
  # ssh_identity_file is used for ssh "-i" flag, its the private key if that is set, or a public key file
  # if an ssh agent is used.
  ssh_identity_file = var.private_key == null ? var.public_key : var.private_key

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
