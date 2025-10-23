#!/usr/bin/env bash
# Check if terraform, packer and hcloud CLIs are present
command -v ssh >/dev/null 2>&1 || {
    echo "openssh is not installed. Install it with 'brew install openssh'."
    exit 1
}

if command -v tofu >/dev/null 2>&1 ; then
    terraform_command=tofu
elif command -v terraform >/dev/null 2>&1 ; then
    terraform_command=terraform
else
    echo "terraform or tofu is not installed. Install it with 'brew tap hashicorp/tap && brew install hashicorp/tap/terraform' or 'brew install opentofu'."
    exit 1
fi

command -v packer >/dev/null 2>&1 || {
    echo "packer is not installed. Install it with 'brew install packer'."
    exit 1
}
command -v hcloud >/dev/null 2>&1 || {
    echo "hcloud (Hetzner CLI) is not installed. Install it with 'brew install hcloud'."
    exit 1
}

# LeapMicro as Default Snapshot
PACKER_TYPE="${1:-leapmicro}"

case "$PACKER_TYPE" in
  microos)
    PACKER_TYPE_DESC="MicroOS"
    ;;
  leapmicro)
    PACKER_TYPE_DESC="LeapMicro"
    ;;
  both)
    PACKER_TYPE_DESC="MicroOS and LeapMicro"
    ;;
  *)
    echo "Invalid parameter: $PACKER_TYPE"
    echo "Allowed values: microos | leapmicro | both"
    exit 1
    ;;
esac

# Ask for the folder name
if [ -z "${folder_name}" ] ; then
    read -p "Enter the name of the folder you want to create (leave empty to use the current directory instead, useful for upgrades): " folder_name
fi

# Ask for the folder path only if folder_name is provided
if [ -n "$folder_name" -a -z "${folder_path}" ]; then
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

# Download kube.tf only if it doesn't exist
if [ ! -e "${folder_path}/kube.tf" ]; then
    curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/kube.tf.example -o "${folder_path}/kube.tf"
else
    echo "kube.tf already exists. Skipping download."
fi

if [[ "$PACKER_TYPE" == "microos" || "$PACKER_TYPE" == "both" ]]; then
    if [ ! -e "${folder_path}/hcloud-microos-snapshots.pkr.hcl" ]; then
        curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/packer-template/hcloud-microos-snapshots.pkr.hcl \
          -o "${folder_path}/hcloud-microos-snapshots.pkr.hcl"
    else
        echo "hcloud-microos-snapshots.pkr.hcl already exists. Skipping download."
    fi
fi

if [[ "$PACKER_TYPE" == "leapmicro" || "$PACKER_TYPE" == "both" ]]; then
    if [ ! -e "${folder_path}/hcloud-leapmicro-snapshots.pkr.hcl" ]; then
        curl -sL https://raw.githubusercontent.com/kube-hetzner/terraform-hcloud-kube-hetzner/master/packer-template/hcloud-leapmicro-snapshots.pkr.hcl \
          -o "${folder_path}/hcloud-leapmicro-snapshots.pkr.hcl"
    else
        echo "hcloud-leapmicro-snapshots.pkr.hcl already exists. Skipping download."
    fi
fi

if [ -z "${create_snapshots}" ] ; then
    echo " "
    echo "The snapshots are required and deployed using packer. If you need specific extra packages, you need to choose no and edit *.pkr.hcl file manually."
    echo "In 99% of cases, we already include the most common packages."
    echo " "
    read -p "Do you want to create the $PACKER_TYPE_DESC snapshots now? (yes/no): " create_snapshots
fi

if [[ "$create_snapshots" =~ ^([Yy]es|[Yy])$ ]]; then
    if [[ -z "$HCLOUD_TOKEN" ]]; then
        read -p "Enter your HCLOUD_TOKEN: " hcloud_token
        export HCLOUD_TOKEN=$hcloud_token
    fi
    if [[ "$PACKER_TYPE" == "microos" || "$PACKER_TYPE" == "both" ]]; then
        echo "Running packer build for hcloud-microos-snapshots.pkr.hcl"
        cd "${folder_path}" && packer init hcloud-microos-snapshots.pkr.hcl && packer build hcloud-microos-snapshots.pkr.hcl
    fi
    if [[ "$PACKER_TYPE" == "leapmicro" || "$PACKER_TYPE" == "both" ]]; then
        echo "Running packer build for hcloud-leapmicro-snapshots.pkr.hcl"
        cd "${folder_path}" && packer init hcloud-leapmicro-snapshots.pkr.hcl && packer build hcloud-leapmicro-snapshots.pkr.hcl
    fi
else
    echo " "
    echo "Snapshots creation skipped."
    echo "To create the snapshot later, run: "

    case "$PACKER_TYPE" in
      microos)
        echo "  packer init hcloud-microos-snapshots.pkr.hcl && packer build hcloud-microos-snapshots.pkr.hcl"
        ;;
      leapmicro)
        echo "  packer init hcloud-leapmicro-snapshots.pkr.hcl && packer build hcloud-leapmicro-snapshots.pkr.hcl"
        ;;
      both)
        echo "  packer init ."
        echo "  packer build hcloud-microos-snapshots.pkr.hcl"
        echo "  packer build hcloud-leapmicro-snapshots.pkr.hcl"
        ;;
    esac
fi

# Output commands
echo " "
echo "Remember, don't skip the hcloud cli, to activate it run 'hcloud context create <project-name>'. It is ideal to quickly debug and allows targeted cleanup when needed!"
echo " "
echo "Before running '${terraform_command} apply', go through the kube.tf file and fill it with your desired values."
