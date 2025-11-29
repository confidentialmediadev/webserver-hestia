#!/bin/bash

# Variables
SERVER_IP="195.26.248.226"
SSH_USER="root"
SSH_PORT="22"

# Step 1: Install HestiaCP
ssh -p $SSH_PORT $SSH_USER@$SERVER_IP << EOF
  echo "Installing HestiaCP..."
  wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install-ubuntu.sh
  bash hst-install-ubuntu.sh -a no -w yes -m yes -x yes -z yes -c yes -t yes -i yes -b yes
EOF

# Step 2: Verify Installation
ssh -p $SSH_PORT $SSH_USER@$SERVER_IP << EOF
  echo "Verifying HestiaCP installation..."
  systemctl status nginx
  systemctl status php*-fpm
  systemctl status mysql
  systemctl status exim4
  systemctl status dovecot
  systemctl status clamav-daemon
  systemctl status spamassassin
  systemctl status fail2ban
EOF

# Step 3: Access HestiaCP Admin Panel
echo "HestiaCP installation complete. Access the admin panel at https://$SERVER_IP:8083"
