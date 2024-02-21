locals {
  kubelet_arg                 = ["cloud-provider=external", "volume-plugin-dir=/var/lib/kubelet/volumeplugins"]
  kube_controller_manager_arg = "flex-volume-plugin-dir=/var/lib/kubelet/volumeplugins"

  # if given as a variable, we want to use the given token. This is needed to restore the cluster
  k3s_token = var.k3s_token == null ? random_password.k3s_token.result : var.k3s_token

  additional_k3s_environment = join("\n",
    [
      for var_name, var_value in var.k3s.additional_environment :
      "${var_name}=\"${var_value}\""
    ]
  )

  install_additional_k3s_environment = <<-EOT
  cat >> /etc/environment <<EOF
  ${local.additional_k3s_environment}
  EOF
  set -a; source /etc/environment; set +a;
  EOT

  install_system_alias = <<-EOT
  cat > /etc/profile.d/00-alias.sh <<EOF
  alias k=kubectl
  EOF
  EOT

  common_pre_install_k3s_commands = concat(
    [
      "set -ex",
      # rename the private network interface to eth1
      "/etc/cloud/rename_interface.sh",
      # prepare the k3s config directory
      "mkdir -p /etc/rancher/k3s",
      # move the config file into place and adjust permissions
      "[ -f /tmp/config.yaml ] && mv /tmp/config.yaml /etc/rancher/k3s/config.yaml",
      "chmod 0600 /etc/rancher/k3s/config.yaml",
      # if the server has already been initialized just stop here
      "[ -e /etc/rancher/k3s/k3s.yaml ] && exit 0",
      local.install_additional_k3s_environment,
      local.install_system_alias,
      local.install_kubectl_bash_completion,
    ],
    # User-defined commands to execute just before installing k3s.
    var.extra.exec.preinstall,
    # Wait for a successful connection to the internet.
    ["timeout 180s /bin/sh -c 'while ! ping -c 1 ${var.network.internet_check_address} >/dev/null 2>&1; do echo \"Ready for k3s installation, waiting for a successful connection to the internet...\"; sleep 5; done; echo Connected'"]
  )

  common_post_install_k3s_commands = concat(var.extra.exec.postinstall, ["restorecon -v /usr/local/bin/k3s"])

  apply_k3s_selinux = ["/sbin/semodule -v -i /usr/share/selinux/packages/k3s.pp"]

  install_k3s_server = concat(local.common_pre_install_k3s_commands, [
    "curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_SELINUX_RPM=true INSTALL_K3S_CHANNEL=${var.k3s.version} INSTALL_K3S_EXEC='server ${var.k3s.exec_server_args}' sh -"
  ], local.apply_k3s_selinux, local.common_post_install_k3s_commands)

  install_k3s_agent = concat(local.common_pre_install_k3s_commands, [
    "curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_SELINUX_RPM=true INSTALL_K3S_CHANNEL=${var.k3s.version} INSTALL_K3S_EXEC='agent ${var.k3s.exec_agent_args}' sh -"
  ], local.apply_k3s_selinux, local.common_post_install_k3s_commands)

  # disable k3s extras
  disable_extras = concat(var.csi.local_storage.enabled ? [] : ["local-storage"], local.using_klipper_lb ? [] : ["servicelb"], ["traefik"], var.enable_metrics_server ? [] : ["metrics-server"])

  install_kubectl_bash_completion = <<-EOT
  cat > /etc/bash_completion.d/kubectl <<EOF
  if command -v kubectl >/dev/null; then
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k
  fi
  EOF
  EOT

  k3s_registries_update_script = <<EOF
DATE=`date +%Y-%m-%d_%H-%M-%S`
if cmp -s /tmp/registries.yaml /etc/rancher/k3s/registries.yaml; then
  echo "No update required to the registries.yaml file"
else
  echo "Backing up /etc/rancher/k3s/registries.yaml to /tmp/registries_$DATE.yaml"
  cp /etc/rancher/k3s/registries.yaml /tmp/registries_$DATE.yaml
  echo "Updated registries.yaml detected, restart of k3s service required"
  cp /tmp/registries.yaml /etc/rancher/k3s/registries.yaml
  if systemctl is-active --quiet k3s; then
    systemctl restart k3s || (echo "Error: Failed to restart k3s. Restoring /etc/rancher/k3s/registries.yaml from backup" && cp /tmp/registries_$DATE.yaml /etc/rancher/k3s/registries.yaml && systemctl restart k3s)
  elif systemctl is-active --quiet k3s-agent; then
    systemctl restart k3s-agent || (echo "Error: Failed to restart k3s-agent. Restoring /etc/rancher/k3s/registries.yaml from backup" && cp /tmp/registries_$DATE.yaml /etc/rancher/k3s/registries.yaml && systemctl restart k3s-agent)
  else
    echo "No active k3s or k3s-agent service found"
  fi
  echo "k3s service or k3s-agent service restarted successfully"
fi
EOF

  k3s_config_update_script = <<EOF
DATE=`date +%Y-%m-%d_%H-%M-%S`
if cmp -s /tmp/config.yaml /etc/rancher/k3s/config.yaml; then
  echo "No update required to the config.yaml file"
else
  if [ -f "/etc/rancher/k3s/config.yaml" ]; then
    echo "Backing up /etc/rancher/k3s/config.yaml to /tmp/config_$DATE.yaml"
    cp /etc/rancher/k3s/config.yaml /tmp/config_$DATE.yaml
  fi
  echo "Updated config.yaml detected, restart of k3s service required"
  cp /tmp/config.yaml /etc/rancher/k3s/config.yaml
  if systemctl is-active --quiet k3s; then
    systemctl restart k3s || (echo "Error: Failed to restart k3s. Restoring /etc/rancher/k3s/config.yaml from backup" && cp /tmp/config_$DATE.yaml /etc/rancher/k3s/config.yaml && systemctl restart k3s)
  elif systemctl is-active --quiet k3s-agent; then
    systemctl restart k3s-agent || (echo "Error: Failed to restart k3s-agent. Restoring /etc/rancher/k3s/config.yaml from backup" && cp /tmp/config_$DATE.yaml /etc/rancher/k3s/config.yaml && systemctl restart k3s-agent)
  else
    echo "No active k3s or k3s-agent service found"
  fi
  echo "k3s service or k3s-agent service (re)started successfully"
fi
EOF
}
