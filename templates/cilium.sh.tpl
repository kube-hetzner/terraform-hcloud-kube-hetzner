#!/usr/bin/env bash

set -xeuo pipefail

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
CILIUM_CLI_VERSION="$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)"

WORKDIR="$(mktemp -d)"
(
  cd "$WORKDIR"
  curl -L --fail --remote-name-all "https://github.com/cilium/cilium-cli/releases/download/$CILIUM_CLI_VERSION/cilium-linux-amd64.tar.gz"{,.sha256sum}
  sha256sum --check "cilium-linux-amd64.tar.gz.sha256sum"
  tar xzvfC "cilium-linux-amd64.tar.gz" .
  ./cilium install --helm-set "ipam.operator.clusterPoolIPv4PodCIDRList[0]=${cluster_cidr_ipv4}"
  ./cilium status --wait
)

rm -rf "$WORKDIR"
