locals {
  # ssh public key
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

  # Final list of packages to install
  needed_packages = join(" ", concat(["k3s-selinux"], var.packages_to_install))

  # the hosts name with its unique suffix attached
  name = "${var.name}-${random_string.server.id}"
}
