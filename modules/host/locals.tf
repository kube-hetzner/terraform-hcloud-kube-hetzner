locals {
  ssh_public_key = trimspace(file(var.public_key))
  # ssh_private_key is either the contents of var.private_key or null to use a ssh agent.
  ssh_private_key = var.private_key == null ? null : trimspace(file(var.private_key))
  # ssh_identity is not set if the private key is passed directly, but if ssh agent is used, the public key tells ssh agent which private key to use.
  # For terraforms provisioner.connection.agent_identity, we need the public key as a string.
  ssh_identity = var.private_key == null ? local.ssh_public_key : null
  # ssh_identity_file is used for ssh "-i" flag, its the private key if that is set, or a public key file
  # if an ssh agent is used.
  ssh_identity_file = var.private_key == null ? var.public_key : var.private_key
  # shared flags for ssh to ignore host keys, to use our ssh identity file for all connections during provisioning.
  ssh_args = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${local.ssh_identity_file}"

  microOS_install_commands = [
    "set -ex",
    "apt-get update",
    "apt-get install -y aria2",
    "aria2c --follow-metalink=mem https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-OpenStack-Cloud.qcow2.meta4",
    "qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda",
  ]
}
