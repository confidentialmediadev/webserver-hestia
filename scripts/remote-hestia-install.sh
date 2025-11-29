#!/bin/bash
set -euo pipefail

echo "Downloading Hestia installer to /root/hst-install-ubuntu.sh"
wget -q -O /root/hst-install-ubuntu.sh https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install-ubuntu.sh
chmod +x /root/hst-install-ubuntu.sh

# Run installer non-interactively with provided admin credentials
echo "Running Hestia installer (non-interactive)..."
/root/hst-install-ubuntu.sh -a no -w yes -m yes -x yes -z yes -c yes -t yes -i yes -b yes -s $(hostname) -e cfeadmin@cfesystems.com -u cfeadmin -p 'dJ3by4jZTCmLxznvxK6DeByX' || true

# Give installer time to finish services, then show key outputs
sleep 2

echo "=== installer logs (tail) ==="
[ -f /var/log/hestia-install.log ] && tail -n 200 /var/log/hestia-install.log || echo "no /var/log/hestia-install.log"

echo "=== root installer logs (if any) ==="
[ -f /root/hst-install.log ] && tail -n 200 /root/hst-install.log || echo "no /root/hst-install.log"

echo "=== service status summary ==="
systemctl --no-pager status hestia || true
systemctl --no-pager status nginx php*-fpm mysql exim4 dovecot fail2ban || true

echo "=== installed packages matching hestia list ==="
dpkg -l | egrep "hestia|nginx|mariadb|mysql|exim4|dovecot|clamav|spamassassin" || true

echo "remote script done"
