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
k3os:
  k3s_args:
  - server
  - "--cluster-init"
  - "--disable-cloud-controller"
  - "--disable=traefik"
  - "--disable=servicelb"
  - "--disable=local-storage"
  - "--flannel-iface=eth1"
  - "--node-ip"
  - "${ip}"
  - "--advertise-address"
  - "${ip}"
  - "--tls-san"
  - "${ip}"
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
