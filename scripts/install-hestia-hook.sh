#!/bin/bash
set -euo pipefail

# Usage: ./install-hestia-hook.sh <host-alias-or-ip> [ssh-port]
# Copies the repo's `scripts/hestia-deploy-hook.sh` to the remote server's
# /etc/letsencrypt/renewal-hooks/deploy/hestia-deploy.sh and sets perms.

REMOTE_HOST=${1:-webserver-hestia}
SSH_PORT=${2:-22}

if [ ! -f scripts/hestia-deploy-hook.sh ]; then
  echo "scripts/hestia-deploy-hook.sh not found in repo. Run from repository root." >&2
  exit 1
fi

echo "Copying hook to $REMOTE_HOST:/tmp/..."
scp -P "$SSH_PORT" scripts/hestia-deploy-hook.sh "$REMOTE_HOST":/tmp/hestia-deploy-hook.sh

echo "Installing hook on remote host"
ssh -p "$SSH_PORT" "$REMOTE_HOST" "sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy && sudo mv /tmp/hestia-deploy-hook.sh /etc/letsencrypt/renewal-hooks/deploy/hestia-deploy.sh && sudo chown root:root /etc/letsencrypt/renewal-hooks/deploy/hestia-deploy.sh && sudo chmod 0755 /etc/letsencrypt/renewal-hooks/deploy/hestia-deploy.sh && echo 'hook installed'"

echo "Done. To verify, run on the remote host: sudo ls -l /etc/letsencrypt/renewal-hooks/deploy/hestia-deploy.sh"
