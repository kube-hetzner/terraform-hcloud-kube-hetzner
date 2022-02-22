
data "remote_file" "kubeconfig" {
  conn {
    host        = module.control_planes[0].ipv4_address
    port        = 22
    user        = "root"
    private_key = local.ssh_private_key
    agent       = var.private_key == null
  }
  path = "/etc/rancher/k3s/k3s.yaml"

  depends_on = [null_resource.control_planes[0]]
}

locals {
  kubeconfig_external = replace(data.remote_file.kubeconfig.content, "127.0.0.1", module.control_planes[0].ipv4_address)
  kubeconfig_parsed   = yamldecode(local.kubeconfig_external)
  kubeconfig_data = {
    host                   = local.kubeconfig_parsed["clusters"][0]["cluster"]["server"]
    client_certificate     = base64decode(local.kubeconfig_parsed["users"][0]["user"]["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig_parsed["users"][0]["user"]["client-key-data"])
    cluster_ca_certificate = base64decode(local.kubeconfig_parsed["clusters"][0]["cluster"]["certificate-authority-data"])
  }
}

resource "local_file" "kubeconfig" {
  sensitive_content = local.kubeconfig_external
  filename          = "kubeconfig.yaml"
  file_permission   = "600"
}
