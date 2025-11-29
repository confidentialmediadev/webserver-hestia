#!/bin/bash
set -euo pipefail

DOMAIN="h26.cfesystems.com"
EMAIL="cfeadmin@cfesystems.com"
HESTIA_SSL_DIR="/usr/local/hestia/ssl"
BACKUP_DIR="/root/hestia-ssl-backups"

echo "== ensure certbot and nginx plugin installed =="
apt-get update -y
apt-get install -y certbot python3-certbot-nginx || apt-get install -y certbot

echo "== request Let's Encrypt certificate for $DOMAIN =="
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" || {
  echo "certbot --nginx failed, trying standalone (will stop nginx)";
  systemctl stop nginx || true;
  certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL";
  systemctl start nginx || true;
}

LE_DIR="/etc/letsencrypt/live/$DOMAIN"
if [ ! -d "$LE_DIR" ]; then
  echo "Let's Encrypt certificate directory $LE_DIR not found; aborting"; exit 1
fi

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
cp -a "$HESTA_SSL_DIR/certificate.crt" "$BACKUP_DIR/certificate.crt.$TIMESTAMP" 2>/dev/null || true
cp -a "$HESTA_SSL_DIR/certificate.key" "$BACKUP_DIR/certificate.key.$TIMESTAMP" 2>/dev/null || true

echo "== copying certs into Hestia SSL dir =="
cp "$LE_DIR/fullchain.pem" "$HESTITA_SSL_CERT_TEMP" 2>/dev/null || true
# Use direct destination
cp "$LE_DIR/fullchain.pem" "$HEISTA_FULLCHAIN_DST" 2>/dev/null || true

# safer: directly overwrite known paths
cp "$LE_DIR/fullchain.pem" "$HESTA_SSL_DIR/certificate.crt"
cp "$LE_DIR/privkey.pem" "$HESTA_SSL_DIR/certificate.key"
chown root:mail "$HESTA_SSL_DIR/certificate.crt" "$HESTA_SSL_DIR/certificate.key" || true
chmod 0640 "$HESTA_SSL_DIR/certificate.crt" || true
chmod 0640 "$HESTA_SSL_DIR/certificate.key" || true

echo "== restart hestia and nginx =="
systemctl restart hestia || true
systemctl restart nginx || true

echo "== show new cert info =="
openssl x509 -in "$HESTA_SSL_DIR/certificate.crt" -noout -subject -issuer -dates || true

echo "done"
