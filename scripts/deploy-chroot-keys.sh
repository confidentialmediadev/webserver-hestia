#!/usr/bin/env bash
set -euo pipefail

# deploy-chroot-keys.sh
# Installs a public key into a chrooted user's authorized_keys under /srv/jail/<user>/home/<user>/.ssh/authorized_keys

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <username> <public-key-file>"
  exit 2
fi

USER="$1"
KEYFILE="$2"

JROOT="/srv/jail/${USER}"
SSHOME="${JROOT}/home/${USER}"
SSH_DIR="${SSHOME}/.ssh"
AUTH_KEYS="${SSH_DIR}/authorized_keys"

if [ ! -d "${SSHOME}" ]; then
  echo "Error: chroot home ${SSHOME} does not exist. Create chroot using hestia-ssh-harden.sh first." >&2
  exit 3
fi

if [ ! -f "${KEYFILE}" ]; then
  echo "Error: key file ${KEYFILE} not found" >&2
  exit 4
fi

sudo mkdir -p "${SSH_DIR}"
sudo chown "${USER}:${USER}" "${SSH_DIR}" || sudo chown "${USER}:${USER}" "${SSH_DIR}" || true
sudo chmod 700 "${SSH_DIR}"

sudo bash -c "cat ${KEYFILE} >> ${AUTH_KEYS}"
sudo chown ${USER}:${USER} "${AUTH_KEYS}" || true
sudo chmod 600 "${AUTH_KEYS}"

echo "Installed key(s) from ${KEYFILE} into ${AUTH_KEYS} (chroot user ${USER})"
exit 0
