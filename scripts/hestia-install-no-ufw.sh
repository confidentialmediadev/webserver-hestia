#!/bin/bash
set -euo pipefail

echo "== remove ufw =="
if systemctl is-active --quiet ufw 2>/dev/null; then
  systemctl stop ufw || true
fi
apt-get purge -y ufw || true
apt-get autoremove -y || true
apt-get update -y || true

echo "== download installer =="
wget -q -O /root/hst-install-ubuntu.sh https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install-ubuntu.sh
chmod +x /root/hst-install-ubuntu.sh

echo "== run installer (non-interactive) =="
# Run installer with provided admin credentials
/root/hst-install-ubuntu.sh -a no -w yes -m yes -x yes -z yes -c yes -t yes -i yes -b yes -s $(hostname) -e cfeadmin@cfesystems.com -u cfeadmin -p 'dJ3by4jZTCmLxznvxK6DeByX' 2>&1 | tee /root/hestia-install-output.log || true

echo "== installer output tail =="
[ -f /root/hestia-install-output.log ] && tail -n 200 /root/hestia-install-output.log || echo "no installer log"

echo "== service status summary =="
systemctl --no-pager status hestia || true
systemctl --no-pager status nginx || true
systemctl --no-pager status php*-fpm || true
systemctl --no-pager status mysql || true
systemctl --no-pager status exim4 || true
systemctl --no-pager status dovecot || true
systemctl --no-pager status fail2ban || true

echo "== package list matching hestia components =="
dpkg -l | egrep "hestia|nginx|mariadb|mysql|exim4|dovecot|clamav|spamassassin" || true

echo "done"
