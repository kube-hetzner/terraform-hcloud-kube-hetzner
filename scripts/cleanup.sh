#!/usr/bin/env bash

DRY_RUN=1

while getopts "hfc:" arg; do
  case $arg in
    h)
      echo "$0 -cfh"
      echo " -c=CLUSTER_NAME Name of the cluster to delete"
      echo " -f Force deletion (per default just a dry run)"
      echo " -h Help"
      exit 0
      ;;
    c)
      CLUSTER_NAME=$OPTARG
      ;;
    f)
      echo "STUFF WILL BE DELETED!"
      DRY_RUN=0
      ;;
    *)
      echo "Unsupported option: $arg"
      exit 1
  esac
done

if [[ -z ${CLUSTER_NAME+x} ]]; then
  echo "-c CLUSTER_NAME is required"
  exit 1
fi

HCLOUD_SELECTOR=(--selector='provisioner=terraform' --selector="cluster=$CLUSTER_NAME")
HCLOUD_OUTPUT_OPTIONS=(-o noheader -o 'columns=id')

VOLUMES=()
while IFS='' read -r line; do VOLUMES+=("$line"); done < <(hcloud volume list "${HCLOUD_SELECTOR[@]}" "${HCLOUD_OUTPUT_OPTIONS[@]}")

SERVERS=()
while IFS='' read -r line; do SERVERS+=("$line"); done < <(hcloud server list "${HCLOUD_SELECTOR[@]}" "${HCLOUD_OUTPUT_OPTIONS[@]}")

PLACEMENT_GROUPS=()
while IFS='' read -r line; do PLACEMENT_GROUPS+=("$line"); done < <(hcloud placement-group list "${HCLOUD_SELECTOR[@]}" "${HCLOUD_OUTPUT_OPTIONS[@]}")

LOAD_BALANCERS=()
while IFS='' read -r line; do LOAD_BALANCER+=("$line"); done < <(hcloud load-balancer list "${HCLOUD_SELECTOR[@]}" "${HCLOUD_OUTPUT_OPTIONS[@]}")

INGRESS_LB=$(hcloud load-balancer list -o noheader -o columns=id,name | grep "${CLUSTER_NAME}" | cut -d ' ' -f1 )

if [[ $INGRESS_LB != "" ]]; then
  LOAD_BALANCERS+=( "$INGRESS_LB" )
fi

FIREWALLS=()
while IFS='' read -r line; do FIREWALLS+=("$line"); done < <(hcloud firewall list "${HCLOUD_SELECTOR[@]}" "${HCLOUD_OUTPUT_OPTIONS[@]}")

NETWORKS=()
while IFS='' read -r line; do NETWORKS+=("$line"); done < <(hcloud network list "${HCLOUD_SELECTOR[@]}" "${HCLOUD_OUTPUT_OPTIONS[@]}")

SSH_KEYS=()
while IFS='' read -r line; do SSH_KEYS+=("$line"); done < <(hcloud ssh-key list "${HCLOUD_SELECTOR[@]}" "${HCLOUD_OUTPUT_OPTIONS[@]}")

function detach_volumes() {
  for ID in "${VOLUMES[@]}"; do
    echo "Detach volume: $ID"
    if (( DRY_RUN == 0 )); then
      hcloud volume detach "$ID"
    fi
  done
}

function delete_volumes() {
  for ID in "${VOLUMES[@]}"; do
    echo "Delete volume: $ID"
    if (( DRY_RUN == 0 )); then
      hcloud volume delete "$ID"
    fi
  done
}

function delete_servers() {
  for ID in "${SERVERS[@]}"; do
    echo "Delete server: $ID"
    if (( DRY_RUN == 0 )); then
      hcloud server delete "$ID"
    fi
  done
}

function delete_placement_groups() {
  for ID in "${PLACEMENT_GROUPS[@]}"; do
    echo "Delete placement-group: $ID"
    if (( DRY_RUN == 0 )); then
      hcloud placement-group delete "$ID"
    fi
  done
}

function delete_load_balancer() {
  for ID in "${LOAD_BALANCERS[@]}"; do
    echo "Delete load-balancer: $ID"
    if (( DRY_RUN == 0 )); then
      hcloud load-balancer delete "$ID"
    fi
  done
}

function delete_firewalls() {
  for ID in "${FIREWALLS[@]}"; do
    echo "Delete firewall: $ID"
    if (( DRY_RUN == 0 )); then
     hcloud firewall delete "$ID"
    fi
  done
}

function delete_networks() {
  for ID in "${NETWORKS[@]}"; do
    echo "Delete network: $ID"
    if (( DRY_RUN == 0 )); then
      hcloud network delete "$ID "
    fi
  done
}

function delete_ssh_keys() {
  for ID in "${SSH_KEYS[@]}"; do
    echo "Delete ssh-key: $ID"
    if (( DRY_RUN == 0 )); then
      hcloud ssh-key delete "$ID"
    fi
  done
}


if (( DRY_RUN > 0 )); then
  echo "Dry run, nothing will be deleted!"
fi


detach_volumes
delete_volumes
delete_servers
delete_placement_groups
delete_load_balancer
delete_firewalls
delete_networks
delete_ssh_keys
