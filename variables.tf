variable "hcloud_token" {
  description = "Hetzner API tokey"
  type        = string
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "public_key" {
  description = "SSH public Key."
  type        = string
}

variable "private_key" {
  description = "SSH private Key."
  type        = string
}

variable "servers_num" {
  description = "Number of control plane nodes."
  default     = 2
}

variable "agents_num" {
  description = "Number of agent nodes."
  default     = 2
}

variable "location" {
  description = "Default server location"
  default     = "fsn1"
}


variable "control_plane_server_type" {
  description = "Default control plane server type"
  default     = "cx11"

}

variable "agent_server_type" {
  description = "Default agent server type"
  default     = "cx21"
}

variable "k3s_server_flags" {
  description = "Important flags to make our setup work"
  default     = "--disable-cloud-controller --disable-network-policy --disable=traefik --disable=servicelb --disable='local-storage' --kubelet-arg='cloud-provider=external' --flannel-backend=none --flannel-iface=ens10"
}

variable "k3s_agent_flags" {
  description = "Important flags to make our setup work"
  default     = "--kubelet-arg='cloud-provider=external' --flannel-iface=ens10"
}

variable "initial_commands" {
  description = "Initial commands to run on each machines."
  default = [
    "dnf upgrade -y",
    "dnf install -y container-selinux selinux-policy-base fail2ban k3s-selinux dnf-automatic jq",
    "systemctl enable --now fail2ban",
    "systemctl enable --now dnf-automatic.timer",
    "systemctl disable firewalld",
    "grubby --args='systemd.unified_cgroup_hierarchy=0' --update-kernel=ALL",
    "sleep 11; shutdown -r +0"
  ]
}

