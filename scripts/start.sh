#!/bin/bash

# Check if terraform, packer and hcloud CLIs are present
command -v terraform >/dev/null 2>&1 || { echo "terraform is not installed. Install it with 'brew install terraform'."; exit 1; }
command -v packer >/dev/null 2>&1 || { echo "packer is not installed. Install it with 'brew install packer'."; exit 1; }
command -v hcloud >/dev/null 2>&1 || { echo "hcloud (Hetzner CLI) is not installed. Install it with 'brew install hcloud'."; exit 1; }

# Ask for the folder name and path
read -p "Enter the name of the folder you want to create (no spaces): " folder_name
read -p "Enter the path to create the folder in (default: current directory): " folder_path

# Set default path if not provided
if [ -z "$folder_path" ]; then
    folder_path="."
fi

# Create the folder
mkdir -p "${folder_path}/${folder_name}"

# Download the required files
curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/next/kube.tf.example -o "${folder_path}/${folder_name}/kube.tf"
curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/next/packer-template/hcloud-microos-snapshot.pkr.hcl -o "${folder_path}/${folder_name}/hcloud-microos-snapshot.pkr.hcl"

# Ask if they want to create the MicroOS snapshot
read -p "Do you want to create the MicroOS snapshot with packer? (yes/no): " create_snapshot

if [ "$create_snapshot" = "yes" ]; then
    read -p "Enter your HCLOUD_TOKEN: " hcloud_token
    export HCLOUD_TOKEN=$hcloud_token
    cd "${folder_path}/${folder_name}" && packer build hcloud-microos-snapshot.pkr.hcl
fi

# Output commands
echo "Before running 'terraform apply', go through the kube.tf file and complete your desired values there."
echo "To create a MicroOS snapshot (if not done already), run 'packer build hcloud-microos-snapshot.pkr.hcl'."
echo "To activate the hcloud CLI for this project, run 'hcloud context create ${folder_name}'."