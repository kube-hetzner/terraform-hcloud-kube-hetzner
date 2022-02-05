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
  }
}
