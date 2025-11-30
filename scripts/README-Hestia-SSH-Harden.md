# Hestia SSH Hardening files

Files created in this workspace (copy these to the server and run with sudo):

- `scripts/99-hestia-sshd.conf` - sshd drop-in config to place at `/etc/ssh/sshd_config.d/99-hestia.conf`
- `scripts/hestia-ssh-harden.sh` - main helper script to create groups, chroot layout, install `fail2ban`, copy drop-in and reload `sshd`.
- `scripts/deploy-chroot-keys.sh` - helper to install a public key into a chrooted user's `authorized_keys`.

Important safety notes before running on the server
- Run these from a separate sudo-capable account/session and keep an existing SSH session open while testing. Do not run unattended.
- The scripts will restrict SSH to the IP `72.46.51.213` using `ufw` if `ufw` is present. Make sure you run the script from that source IP or modify the script before running.
- The scripts will create groups `sshadmins` and `sftpclients` (and a user `aicfe` if it does not exist).
- The default behaviour in the drop-in sets `PasswordAuthentication no` globally and enables password auth only for members of the `sftpclients` group. Admins should use keys.

Recommended run sequence (on the server):

1. Upload the files to the server (e.g., to `~/hestia-ssh-hardening/`) and inspect them.

2. (Optional) Edit `/home/<you>/hestia-ssh-hardening/scripts/hestia-ssh-harden.sh` to change variables at top if needed:
   - `ADMIN_USER` (default `cfeaiagent`)
   - `SFTP_USERS` (default `aicfe`)
   - `ALLOWED_IP` (default `72.46.51.213`)

3. Verify your current sshd config syntax and backup (the script does this, but you can do a manual backup too):
```bash
sudo cp -a /etc/ssh/sshd_config /root/sshd_config.pre_harden
sudo mkdir -p /root/sshd_config.d.pre_harden
sudo cp -a /etc/ssh/sshd_config.d/* /root/sshd_config.d.pre_harden/ || true
sudo sshd -t
```

4. Run the hardening script (from the directory that contains the scripts):
```bash
cd ~/hestia-ssh-hardening/scripts
sudo bash ./hestia-ssh-harden.sh
```

5. Deploy admin public key for `cfeaiagent` (on your workstation):
```bash
# from your workstation, copy the pub key file to server, e.g. /tmp/cfeaiagent.pub
scp ~/.ssh/cfeaiagent.pub youruser@server:/tmp/cfeaiagent.pub
sudo bash ./deploy-chroot-keys.sh cfeaiagent /tmp/cfeaiagent.pub
```

6. Deploy SFTP user keys (if you prefer keys) instead of password auth:
```bash
sudo bash ./deploy-chroot-keys.sh aicfe /tmp/aicfe.pub
```

7. Test connections from your admin workstation (IP 72.46.51.213):
   - Key login for admin: `ssh -i ~/.ssh/cfeaiagent cfeaiagent@server`
   - SFTP client (password or key): `sftp aicfe@server` and then `cd data` (or the directory you created)

8. If anything breaks, rollback using backups created under `/root/hestia-ssh-backups-<timestamp>` by the script.

PAM lockout (manual step recommended)
- Automated changes to PAM are risky; instead follow distribution docs. On Ubuntu 24.04, consider `pam_faillock` or `pam_tally2` alternatives. If you want, I can provide the exact PAM snippets and instructions to apply them safely.

If you want me to generate the PAM snippet and a safe apply sequence, say so and I will create it as a separate file.
