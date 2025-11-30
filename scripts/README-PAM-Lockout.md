# PAM Lockout (Ubuntu 24.04) — README

This documents the helper `scripts/enable-pam-lockout.sh` which prepares and (optionally) applies PAM account lockout rules for SSH, using either `pam_faillock` or `pam_tally2` depending on what's installed on the system.

What the script does
- Creates backups of `/etc/pam.d/common-auth`, `/etc/pam.d/common-account`, and `/etc/pam.d/sshd` in `/root/hestia-pam-backups-<timestamp>`.
- Detects whether `pam_faillock` or `pam_tally2` is available on the host.
- Prepares modified `.new` versions of the three PAM files with deny/unlock_time settings.
- Prints the prepared files to the console for manual inspection.
- Applies the changes only after you type `yes` to confirm.

Default parameters
- deny = 5 failed attempts
- unlock_time = 900 seconds (15 minutes)

Important safety notes
- PAM changes can lock out logins including your admin access if applied incorrectly. Keep one root/admin SSH session open while you test.
- The script adds the lockout module lines, but it does not remove existing lines. If you already have a similar setup you may need to manually merge.
- If no relevant PAM module is found the script will not apply anything and will tell you what to install.

How to run
1. Upload the script to the server (if not already present) and inspect it:
```bash
sudo less scripts/enable-pam-lockout.sh
```

2. Run it with sudo from the repo directory:
```bash
cd ~/hestia-ssh-hardening/scripts
sudo bash ./enable-pam-lockout.sh
```

3. The script will show the proposed changes. If they look correct, type `yes` when prompted to apply them. Otherwise, exit and inspect the `.new` files under `/etc/pam.d`.

Undo / rollback
- The script stores backups in `/root/hestia-pam-backups-<timestamp>`. To restore:
```bash
sudo cp /root/hestia-pam-backups-<timestamp>/common-auth /etc/pam.d/common-auth
sudo cp /root/hestia-pam-backups-<timestamp>/common-account /etc/pam.d/common-account
sudo cp /root/hestia-pam-backups-<timestamp>/sshd /etc/pam.d/sshd
```

Reset counters
- For `pam_faillock`:
```bash
sudo pam_faillock --user <username> --reset
```
- For `pam_tally2`:
```bash
sudo pam_tally2 -u <username> -r
```

If you want, I can: produce a conservative `jail.local` change for Fail2Ban to correlate with PAM lockouts, or tweak deny/unlock_time values. Tell me what values you'd like if different from the defaults (5 tries, 15 minutes). Otherwise run the script and test from a second open session.
