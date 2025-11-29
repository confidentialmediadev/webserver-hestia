#!/bin/bash

# Variables
SERVER_IP="195.26.248.226"
SSH_USER="root"
SSH_PORT="22"
REPO_PATH="/opt/cfe-automation"

# Step 1: Add SSH Public Key
echo "Adding SSH public key to the server..."
ssh-copy-id -i ~/.ssh/id_rsa.pub -p $SSH_PORT $SSH_USER@$SERVER_IP

# Step 2: Disable Password Authentication
ssh -p $SSH_PORT $SSH_USER@$SERVER_IP << EOF
  echo "Disabling password authentication..."
  sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
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

echo "VPS provisioning and repository initialization complete."
