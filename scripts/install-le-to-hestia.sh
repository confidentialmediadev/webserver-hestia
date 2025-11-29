#!/bin/bash
set -euo pipefail

DOMAIN="h26.cfesystems.com"
HESTA_SSL_DIR="/usr/local/hestia/ssl"
LE_DIR="/etc/letsencrypt/live/$DOMAIN"
BACKUP_DIR="/root/hestia-ssl-backups"

echo "Checking Let's Encrypt certs at $LE_DIR"
if [ ! -d "$LE_DIR" ]; then
  echo "ERROR: $LE_DIR does not exist. Aborting." >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
TS=$(date +%Y%m%d-%H%M%S)

if [ -f "$HESTA_SSL_DIR/certificate.crt" ]; then
  echo "Backing up existing Hestia certs to $BACKUP_DIR"
  cp -a "$HESTA_SSL_DIR/certificate.crt" "$BACKUP_DIR/certificate.crt.$TS"
fi
if [ -f "$HESTA_SSL_DIR/certificate.key" ]; then
  cp -a "$HESTA_SSL_DIR/certificate.key" "$BACKUP_DIR/certificate.key.$TS"
fi

echo "Copying Let's Encrypt certs into Hestia SSL directory"
cp "$LE_DIR/fullchain.pem" "$HESTA_SSL_DIR/certificate.crt"
cp "$LE_DIR/privkey.pem" "$HESTA_SSL_DIR/certificate.key"

echo "Setting ownership and permissions"
chown root:mail "$HESTA_SSL_DIR/certificate.crt" "$HESTA_SSL_DIR/certificate.key" || true
chmod 0640 "$HESTA_SSL_DIR/certificate.crt" || true
chmod 0640 "$HESTA_SSL_DIR/certificate.key" || true

echo "Restarting services"
systemctl restart hestia || true
systemctl restart nginx || true

echo "New certificate details:"
openssl x509 -in "$HESTA_SSL_DIR/certificate.crt" -noout -subject -issuer -dates || true

echo "Verify via openssl s_client (brief):"
openssl s_client -connect ${DOMAIN}:8083 -servername ${DOMAIN} -showcerts </dev/null 2>/dev/null | sed -n '1,6p' || true

echo "Done"
