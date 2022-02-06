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
        "path": "/etc/hostname",
        "mode": 420,
        "overwrite": true,
        "contents": { "source": "data:,${name}" }
      },
      {
        "path": "/etc/sysconfig/network/ifcfg-eth1",
        "mode": 420,
        "overwrite": true,
        "contents": { "source": "data:,BOOTPROTO%3D%27dhcp%27%0ASTARTMODE%3D%27auto%27" }
      }
    ]
  }
}
