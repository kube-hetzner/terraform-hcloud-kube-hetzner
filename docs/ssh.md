Kube-Hetzner requires you to have a recent version of OpenSSH (>=6.5) installed on your client, and the use of a key-pair generated with either of the following algorithms:

- ssh-ed25519 (preferred, and most simple to use without passphrase)
- rsa-sha2-512
- rsa-sha2-256

If your key-pair is of the `ssh-ed25519` sort (useful command `ssh-keygen -t ed25519`), and without of passphrase, you do not need to do anything else. Just set `public_key` and `private_key` to their respective path values in your kube.tf file.

---

Otherwise, for a key-pair with passphrase or a device like a Yubikey, make sure you have an SSH agent running and your key is loaded with:

```bash
eval ssh-agent $SHELL
ssh-add ~/.ssh/my_private-key_id
```

Verify it is loaded with:

```bash
ssh-add -l
```

Then set `private_key = null` in your kube.tf file, as it will be read from the ssh-agent automatically.
