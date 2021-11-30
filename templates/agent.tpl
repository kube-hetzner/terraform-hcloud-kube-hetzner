ssh_authorized_keys:
- ${ssh_public_key}
hostname: ${name}
k3os:
  k3s_args:
  - server
  --node-ip=${ip} 
  --advertise-address=${ip} 
  --bind-address=${ip} 
  --tls-san=${ip}
  --disable-cloud-controller
  --disable-network-policy
  --disable=traefik
  --disable=servicelb
  --disable='local-storage'
  --kubelet-arg='cloud-provider=external'
  token: ${k3s_token}
  ntp_servers:
  - 0.de.pool.ntp.org
  - 1.de.pool.ntp.org
  dns_nameservers:
  - 8.8.8.8
  - 1.1.1.1
  - 8.8.4.4
  - 1.0.0.1
  - 2001:4860:4860::8888
  - 2606:4700:4700::1111
  - 2001:4860:4860::8844
  - 2606:4700:4700::1001
