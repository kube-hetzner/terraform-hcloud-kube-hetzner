#!/bin/bash

# Check if terraform, packer and hcloud CLIs are present
command -v terraform >/dev/null 2>&1 || { echo "terraform is not installed. Install it with 'brew install terraform'."; exit 1; }
command -v packer >/dev/null 2>&1 || { echo "packer is not installed. Install it with 'brew install packer'."; exit 1; }
command -v hcloud >/dev/null 2>&1 || { echo "hcloud (Hetzner CLI) is not installed. Install it with 'brew install hcloud'."; exit 1; }

# Ask for the folder name
read -p "Enter the name of the folder you want to create (leave empty to use the current directory instead, useful for upgrades): " folder_name

# Ask for the folder path only if folder_name is provided
if [ -n "$folder_name" ]; then
    read -p "Enter the path to create the folder in (default: current path): " folder_path
fi

# Set default path if not provided
if [ -z "$folder_path" ]; then
    folder_path="."
fi

# Create the folder if folder_name is provided
if [ -n "$folder_name" ]; then
    mkdir -p "${folder_path}/${folder_name}"
    folder_path="${folder_path}/${folder_name}"
fi

# Download the required files only if they don't exist
if [ ! -e "${folder_path}/kube.tf" ]; then
    curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/kube.tf.example -o "${folder_path}/kube.tf"
else
    echo "kube.tf already exists. Skipping download."
fi

if [ ! -e "${folder_path}/hcloud-microos-snapshot.pkr.hcl" ]; then
    curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/packer-template/hcloud-microos-snapshot.pkr.hcl -o "${folder_path}/hcloud-microos-snapshot.pkr.hcl"
else
    echo "hcloud-microos-snapshot.pkr.hcl already exists. Skipping download."
fi

# Ask if they want to create the MicroOS snapshot
echo " "
echo "The snapshot is required and deployed using packer. If you need specific extra packages, you need to choose no and edit hcloud-microos-snapshot.pkr.hcl file manually. This is not needed in 99% of cases, as we already include the most common packages."
echo " "
read -p "Do you want to create the MicroOS snapshot with packer now? (yes/no): " create_snapshot

if [ "$create_snapshot" = "yes" ]; then
    read -p "Enter your HCLOUD_TOKEN: " hcloud_token
    export HCLOUD_TOKEN=$hcloud_token
    echo "Running: packer build packer build hcloud-microos-snapshot.pkr.hcl"
    cd "${folder_path}/${folder_name}" && packer build hcloud-microos-snapshot.pkr.hcl
else
    echo " "
    echo "You can create the snapshot later by running 'packer build hcloud-microos-snapshot.pkr.hcl' in the folder."
fi

# Output commands
echo " "
echo "Before running 'terraform apply', go through the kube.tf file and complete your desired values there."
echo "To activate the hcloud CLI for this project, run 'hcloud context create <project-name>'. It is a lot more practical than using the Hetzner UI, and allows for easy cleanup or debugging."