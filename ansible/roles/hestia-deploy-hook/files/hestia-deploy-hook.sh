#!/bin/bash
set -euo pipefail

DOMAIN="h26.cfesystems.com"
HESTIA_SSL_DIR="/usr/local/hestia/ssl"
BACKUP_DIR="/root/hestia-ssl-backups"

mkdir -p "$BACKUP_DIR"
TS=$(date +%Y%m%d-%H%M%S)

if [ -f "$HESTIA_SSL_DIR/certificate.crt" ]; then
  cp -a "$HESTIA_SSL_DIR/certificate.crt" "$BACKUP_DIR/certificate.crt.$TS"
fi
if [ -f "$HESTIA_SSL_DIR/certificate.key" ]; then
  cp -a "$HESTIA_SSL_DIR/certificate.key" "$BACKUP_DIR/certificate.key.$TS"
fi

cp -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$HESTIA_SSL_DIR/certificate.crt"
cp -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$HESTIA_SSL_DIR/certificate.key"

chown root:mail "$HESTIA_SSL_DIR/certificate.crt" "$HESTIA_SSL_DIR/certificate.key" || true
chmod 0640 "$HESTIA_SSL_DIR/certificate.crt" || true
chmod 0640 "$HESTIA_SSL_DIR/certificate.key" || true

systemctl restart hestia || true
systemctl reload nginx || systemctl restart nginx || true

logger "hestia-deploy-hook: deployed cert for $DOMAIN"
echo "hestia-deploy-hook: deployed cert for $DOMAIN"
