#!/bin/bash

# Variables
SERVER_IP="195.26.248.226"
SSH_USER="root"
SSH_PORT="22"
REPO_PATH="/opt/cfe-automation"
ADMIN_USER="cfeaiagent"

# Step 1: Add SSH Public Key
echo "Adding SSH public key to the server..."
ssh-copy-id -i ~/.ssh/cfeaiagent.pub -p $SSH_PORT $SSH_USER@$SERVER_IP

# Step 2: Create Admin User and Configure SSH
ssh -p $SSH_PORT $SSH_USER@$SERVER_IP << EOF
  echo "Creating admin user and configuring SSH..."
  adduser --disabled-password --gecos "" $ADMIN_USER
  usermod -aG sudo $ADMIN_USER

  mkdir -p /home/$ADMIN_USER/.ssh
  chmod 700 /home/$ADMIN_USER/.ssh
  cp /root/.ssh/authorized_keys /home/$ADMIN_USER/.ssh/authorized_keys
  chmod 600 /home/$ADMIN_USER/.ssh/authorized_keys
  chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER

  echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

  sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  systemctl disable --now ssh.socket || true
  systemctl enable ssh.service || true
  systemctl restart sshd
EOF

# Step 3: Initialize Automation Repository
ssh -p $SSH_PORT $SSH_USER@$SERVER_IP << EOF
  echo "Initializing automation repository..."
  mkdir -p $REPO_PATH/{ansible,scripts,config,docs,tests}
  cd $REPO_PATH
  git init
  echo "# CFE Web Host Automation Repository" > README.md
  echo "*.log" > .gitignore
  echo "*.env" >> .gitignore
  git add .
  git commit -m "Initialize CFE Web Host Automation Repository"
EOF

# Step 3.1: Install Certbot -> Hestia deploy hook
echo "Installing Hestia deploy hook on the server..."
# Copy local script to server /tmp and move into place with sudo
scp -P $SSH_PORT scripts/hestia-deploy-hook.sh $SSH_USER@$SERVER_IP:/tmp/hestia-deploy-hook.sh
ssh -p $SSH_PORT $SSH_USER@$SERVER_IP << EOF
  sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
  sudo mv /tmp/hestia-deploy-hook.sh /etc/letsencrypt/renewal-hooks/deploy/hestia-deploy.sh
  sudo chown root:root /etc/letsencrypt/renewal-hooks/deploy/hestia-deploy.sh
  sudo chmod 0755 /etc/letsencrypt/renewal-hooks/deploy/hestia-deploy.sh
  echo "Deployed hestia-deploy hook"
EOF

# Step 4: Configure Firewall and Basic Security
ssh -p $SSH_PORT $SSH_USER@$SERVER_IP << EOF
  echo "Configuring firewall and basic security..."
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow from 72.46.51.213 to any port 22 proto tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable

  apt update && apt upgrade -y
  apt install -y sudo ufw fail2ban unattended-upgrades curl htop ncdu git

  systemctl enable --now fail2ban

  echo "Configuring unattended security updates..."
  echo "APT::Periodic::Update-Package-Lists \"1\";" > /etc/apt/apt.conf.d/20auto-upgrades
  echo "APT::Periodic::Unattended-Upgrade \"1\";" >> /etc/apt/apt.conf.d/20auto-upgrades
  systemctl restart unattended-upgrades || true
EOF

echo "VPS provisioning and repository initialization complete."
