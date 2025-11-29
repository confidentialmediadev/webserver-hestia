#!/bin/bash
set -euo pipefail

echo "== bind backup check =="
if [ -d /etc/bind ]; then
  ts=$(date +%Y%m%d-%H%M%S)
  tar -czf /root/bind-backup-${ts}.tgz /etc/bind && echo "backup created: /root/bind-backup-${ts}.tgz" || echo "failed to create backup"
else
  echo "/etc/bind not present, nothing to back up"
fi

echo "== stopping bind9 =="
if systemctl is-active --quiet bind9; then
  systemctl stop bind9 && echo "bind9 stopped"
else
  echo "bind9 not running or not installed"
fi

echo "== purge bind packages =="
apt-get purge -y bind9 bind9-dnsutils bind9-host bind9-libs || true
apt-get autoremove -y || true
apt-get update -y || true

echo "== remaining bind packages (if any) =="
dpkg -l | egrep "bind9|bind9-dnsutils|bind9-host|bind9-libs" || echo "none"

echo "== backup files listing =="
ls -l /root/bind-backup-* 2>/dev/null || true

echo "== done =="
