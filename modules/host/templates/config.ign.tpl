{
  "ignition": {
    "version": "3.0.0"
  },
  "passwd": {
    "users": [
      {
        "name": "root",
        "sshAuthorizedKeys": [
          "${ssh_public_key}"
        ]
      }
    ]
  },
  "storage": {
    "files": [
      {
        "path": "/etc/sysconfig/network/ifcfg-eth1",
        "mode": 420,
        "overwrite": true,
        "contents": { "source": "data:,BOOTPROTO%3D%27dhcp%27%0ASTARTMODE%3D%27auto%27" }
      },
      {
        "path": "/etc/ssh/sshd_config.d/kube-hetzner.conf",
        "mode": 420,
        "overwrite": true,
        "contents": { "source": "data:,PasswordAuthentication%20no%0AX11Forwarding%20no%0AMaxAuthTries%202%0AAllowTcpForwarding%20no%0AAllowAgentForwarding%20no%0AAuthorizedKeysFile%20.ssh%2Fauthorized_keys" }
      }
    ]
  }
}
