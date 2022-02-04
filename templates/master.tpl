ssh_authorized_keys:
- ${ssh_public_key}
hostname: ${name}
boot_cmd:
- |
  echo 'auto eth0
  iface eth0 inet dhcp
  auto eth1
  iface eth1 inet dhcp' > /etc/network/interfaces
- rc-update del connman boot
- rc-update add networking boot
- rc-update add ntpd default
run_cmd:
- sh -c "ip route add 10.0.0.0/16 via 10.0.0.1 dev eth1"
k3os:
  k3s_args:
  - server
  - "--cluster-init"
  - "--disable-cloud-controller"
  - "--disable=servicelb"
  - "--disable=local-storage"
  - "--flannel-iface=eth1"
  - "--node-ip"
  - "${master_ip}"
  - "--advertise-address"
  - "${master_ip}"
  - "--tls-san"
  - "${master_ip}"
  - "--kubelet-arg"
  - "cloud-provider=external"
  token: ${k3s_token}
  ntp_servers:
  - 0.de.pool.ntp.org
  - 1.de.pool.ntp.org
  dns_nameservers:
  - 8.8.8.8
  - 1.1.1.1
  - 2001:4860:4860::8888
  - 2606:4700:4700::1111
