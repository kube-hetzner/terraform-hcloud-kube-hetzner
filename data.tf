data "github_release" "hetzner_ccm" {
  count       = var.hetzner_ccm_version == null ? 1 : 0
  repository  = "hcloud-cloud-controller-manager"
  owner       = "hetznercloud"
  retrieve_by = "latest"
}

data "github_release" "hetzner_csi" {
  count       = var.hetzner_csi_version == null && !var.disable_hetzner_csi ? 1 : 0
  repository  = "csi-driver"
  owner       = "hetznercloud"
  retrieve_by = "latest"
}

// github_release for kured
data "github_release" "kured" {
  count       = var.kured_version == null ? 1 : 0
  repository  = "kured"
  owner       = "kubereboot"
  retrieve_by = "latest"
}

// github_release for kured
data "github_release" "calico" {
  count       = var.calico_version == null && var.cni_plugin == "calico" ? 1 : 0
  repository  = "calico"
  owner       = "projectcalico"
  retrieve_by = "latest"
}

data "hcloud_ssh_keys" "keys_by_selector" {
  count         = length(var.ssh_hcloud_key_label) > 0 ? 1 : 0
  with_selector = var.ssh_hcloud_key_label
}

data "external" "my_ip" {
  count = local.is_ref_myipv4_used ? 1 : 0

  program = [
    "bash",
    "-c",
    <<-EOT
      set -euo pipefail
      error_exit() {
        echo "Error: $1" >&2
        exit 1
      }

      if ! command -v dig &> /dev/null; then
        error_exit "'dig' command not found. Please install it (e.g., 'apt-get install dnsutils' or 'yum install bind-utils')."
      fi
      IPV4=$(dig +time=5 +tries=2 -4 +short myip.opendns.com @resolver1.opendns.com | head -n 1)
      if [ -z "$IPV4" ]; then
        IPV4=$(dig +time=5 +tries=2 -4 +short TXT o-o.myaddr.l.google.com @ns1.google.com | head -n 1 | tr -d '"')
      fi
      if [ -z "$IPV4" ]; then
        error_exit "Failed to retrieve public IPv4 address. The command returned an empty string. Please check network connectivity."
      fi
      if [[ "$IPV4" =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
        echo "{\"ipv4\": \"$IPV4\"}"
      else
        error_exit "Retrieved value '$IPV4' is not a valid public IPv4 address."
      fi
    EOT
  ]
}
