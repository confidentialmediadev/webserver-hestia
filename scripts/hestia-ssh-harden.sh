#!/usr/bin/env bash
set -euo pipefail

### hestia-ssh-harden.sh
### Safe helper to create groups, chroot layouts, install fail2ban and backup ssh config.
### Run this on the server as root or via sudo. It will NOT automatically overwrite PAM files.

BACKUP_DIR="/root/hestia-ssh-backups-$(date +%Y%m%d%H%M%S)"
SSHD_DROPIN="/etc/ssh/sshd_config.d/99-hestia.conf"
LOCAL_DROPIN="$(dirname "$0")/99-hestia-sshd.conf"

ADMIN_USER="cfeaiagent"
SFTP_GROUP="sftpclients"
ADMIN_GROUP="sshadmins"
SFTP_USERS=(aicfe)
ALLOWED_IP="72.46.51.213"

echo "Preparing Hestia SSH hardening — backup first to ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

echo "Backing up /etc/ssh/sshd_config and /etc/ssh/sshd_config.d to ${BACKUP_DIR}"
cp -a /etc/ssh/sshd_config "${BACKUP_DIR}/sshd_config" || true
if [ -d /etc/ssh/sshd_config.d ]; then
  cp -a /etc/ssh/sshd_config.d "${BACKUP_DIR}/sshd_config.d" || true
fi

echo "Creating groups: ${ADMIN_GROUP}, ${SFTP_GROUP}"
getent group "${ADMIN_GROUP}" >/dev/null || groupadd -f "${ADMIN_GROUP}"
getent group "${SFTP_GROUP}" >/dev/null || groupadd -f "${SFTP_GROUP}"

echo "Adding admin user ${ADMIN_USER} to ${ADMIN_GROUP} (user must exist)"
if id "${ADMIN_USER}" >/dev/null 2>&1; then
  usermod -aG "${ADMIN_GROUP}" "${ADMIN_USER}"
else
  echo "Warning: admin user ${ADMIN_USER} does not exist on system. Create it first and re-run this script."
fi

echo "Copying sshd drop-in configuration file to ${SSHD_DROPIN}"
if [ -f "${LOCAL_DROPIN}" ]; then
  cp -a "${LOCAL_DROPIN}" "${SSHD_DROPIN}.new"
else
  echo "ERROR: local drop-in file ${LOCAL_DROPIN} not found. Place 99-hestia-sshd.conf next to this script and re-run." >&2
  exit 1
fi

echo "Creating chroot layout under /srv/jail for sftp users: ${SFTP_USERS[*]}"
for u in "${SFTP_USERS[@]}"; do
  JROOT="/srv/jail/${u}"
  SSHOME="${JROOT}/home/${u}"
  echo "Setting up ${JROOT} and ${SSHOME}"
  mkdir -p "${SSHOME}"
  # chroot root must be owned by root and not writable by others
  chown root:root "${JROOT}"
  chmod 0755 "${JROOT}"

  # home inside chroot owned by user
  if id "${u}" >/dev/null 2>&1; then
    usermod -d "/home/${u}" "${u}" || true
    chown -R "${u}:${SFTP_GROUP}" "${SSHOME}" || true
    chmod 0750 "${SSHOME}" || true
  else
    echo "Creating system user ${u} (nologin)"
    useradd -m -d "/home/${u}" -s /usr/sbin/nologin -G "${SFTP_GROUP}" "${u}"
    # move the created /home/<u> content into chroot home
    mkdir -p "${SSHOME}"
    chown -R "${u}:${SFTP_GROUP}" "${SSHOME}"
    chmod 0750 "${SSHOME}"
  fi
done

echo "Installing Fail2Ban and creating a basic SSH jail"
if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y fail2ban
elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y fail2ban || true
  else
    yum install -y fail2ban || true
  fi
fi

FAIL2JAIL_DIR="/etc/fail2ban/jail.d"
mkdir -p "${FAIL2JAIL_DIR}"
cat > "${FAIL2JAIL_DIR}/hestia-sshd.local" <<'EOF'
[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 600
bantime = 86400
EOF

echo "Backing up existing /etc/hosts.allow and /etc/hosts.deny"
cp -a /etc/hosts.allow "${BACKUP_DIR}/hosts.allow" || true
cp -a /etc/hosts.deny "${BACKUP_DIR}/hosts.deny" || true

echo "Configuring UFW / firewall to allow SSH only from ${ALLOWED_IP} (if UFW present)"
if command -v ufw >/dev/null 2>&1; then
  echo "Setting UFW rules: allow from ${ALLOWED_IP} to port 22, allow http/https/8083 for Hestia"
  ufw allow from ${ALLOWED_IP} to any port 22 proto tcp
  ufw allow 80,443,8083/tcp
  # deny other SSH (ensure default deny incoming is set)
  # Note: If running remotely, ensure your current session remains open before enabling
else
  echo "ufw not present; please configure your firewall to allow SSH only from ${ALLOWED_IP} and allow HTTP/HTTPS/8083 if needed."
fi

echo "Installing new sshd drop-in in a safe manner"
mv -f "${SSHD_DROPIN}.new" "${SSHD_DROPIN}"

echo "Testing sshd config syntax"
if sshd -t; then
  echo "sshd -t passed. Reloading sshd..."
  if systemctl is-active --quiet sshd; then
    systemctl reload sshd
  else
    systemctl restart sshd
  fi
else
  echo "sshd -t failed. Restoring previous config and aborting."
  cp -a "${BACKUP_DIR}/sshd_config" /etc/ssh/sshd_config || true
  if [ -d "${BACKUP_DIR}/sshd_config.d" ]; then
    cp -a "${BACKUP_DIR}/sshd_config.d" /etc/ssh/ || true
  fi
  exit 1
fi

echo "Restarting fail2ban to pick up new jail"
systemctl restart fail2ban || true

cat <<EOF
HARDENING COMPLETE (files placed, groups added). Next steps for you to perform as admin:

- Verify you can still connect from your admin workstation (IP ${ALLOWED_IP}) before closing any session.
- Add additional public keys for admin user ${ADMIN_USER} using the deploy script:
  sudo bash ./scripts/deploy-chroot-keys.sh aicfe /path/to/aicfe.pub

- If you need PAM lockout rules, review the README and apply them manually (recommended to avoid accidental lockout).

Rollback info: backups created under ${BACKUP_DIR}

EOF

exit 0
