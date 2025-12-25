#!/bin/bash
set -euo pipefail

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

apt-get update

# --- SSH Hardening (Contabo-Specific) ---
echo "Hardening SSH for Contabo environment..."

# 1. Add cfeaiagent key to root's authorized_keys
echo "Adding cfeaiagent key to root authorized_keys..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

CFE_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCpFtv3jpQleyVf4c3/Ia+PEzeU3D4gwaFwuOz1zL71 cfeaiagent"
CM_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDF5FSnN13q4pXO+ZjCTsOWVzbAz25mQEJ8A8R8DGzFF confidentialmediadev@gmail.com"
GH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG5U9Au1TU/ShCbOQJlK8fBbrD0VXEtXAiHMhlEndZCB deploy:bribiz/webserver-hestia"

if ! grep -qF "$CFE_KEY" /root/.ssh/authorized_keys; then
    echo "$CFE_KEY" >> /root/.ssh/authorized_keys
    echo "$CM_KEY" >> /root/.ssh/authorized_keys
    echo "$GH_KEY" >> /root/.ssh/authorized_keys
    echo "✓ Added keys to root"
else
    echo "✓ Keys already exist in root authorized_keys"
fi

# 2. Create cfeaiagent sudo user (idempotent)
echo "Setting up cfeaiagent sudo user..."
if ! id -u cfeaiagent &>/dev/null; then
    adduser --disabled-password --gecos "CFE AI Agent" cfeaiagent
    echo "✓ Created user cfeaiagent"
else
    echo "✓ User cfeaiagent already exists"
fi

# Add to sudo group if not already
if ! groups cfeaiagent | grep -q sudo; then
    usermod -aG sudo cfeaiagent
    echo "✓ Added cfeaiagent to sudo group"
else
    echo "✓ cfeaiagent already in sudo group"
fi

# Setup SSH key for cfeaiagent
mkdir -p /home/cfeaiagent/.ssh
chmod 700 /home/cfeaiagent/.ssh
touch /home/cfeaiagent/.ssh/authorized_keys
chmod 600 /home/cfeaiagent/.ssh/authorized_keys
chown -R cfeaiagent:cfeaiagent /home/cfeaiagent/.ssh

if ! grep -qF "$CFE_KEY" /home/cfeaiagent/.ssh/authorized_keys; then
    echo "$CFE_KEY" >> /home/cfeaiagent/.ssh/authorized_keys
    echo "$CM_KEY" >> /home/cfeaiagent/.ssh/authorized_keys
    echo "$GH_KEY" >> /home/cfeaiagent/.ssh/authorized_keys
    echo "✓ Added keys to user authorized_keys"
else
    echo "✓ Keys already exist in user authorized_keys"
fi

# Configure passwordless sudo for cfeaiagent
echo "Configuring passwordless sudo for cfeaiagent..."
if [ ! -f /etc/sudoers.d/cfeaiagent ]; then
    echo "cfeaiagent ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/cfeaiagent
    chmod 440 /etc/sudoers.d/cfeaiagent
    echo "✓ Passwordless sudo configured for cfeaiagent"
else
    echo "✓ Passwordless sudo already configured"
fi

# 3. Deploy SSH hardening config (99-cfe-hardening.conf)
echo "Deploying SSH hardening configuration..."
cat > /etc/ssh/sshd_config.d/99-cfe-hardening.conf << 'EOF'
# CFE SSH hardening - loaded last

Port 22
Protocol 2

PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no

PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

AllowUsers cfeaiagent

X11Forwarding no
AllowTcpForwarding yes
PermitTunnel no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

echo "✓ SSH hardening config deployed to /etc/ssh/sshd_config.d/99-cfe-hardening.conf"

# 4. Switch from socket to daemon mode (if needed)
echo "Checking SSH service mode..."
if systemctl is-active --quiet ssh.socket; then
    echo "SSH is running in socket mode. Switching to daemon mode..."
    systemctl stop ssh.socket
    systemctl disable ssh.socket
    systemctl enable ssh.service
    systemctl start ssh.service
    echo "✓ Switched to SSH daemon mode"
else
    echo "✓ SSH already running in daemon mode"
    systemctl enable ssh.service
    systemctl restart ssh.service
fi

echo "✓ SSH hardening complete"


# --- Verification ---
echo "SSH Config:"
grep PasswordAuthentication /etc/ssh/sshd_config

