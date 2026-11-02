#!/usr/bin/env bash
# ==============================================================================
# The Hive — Bare-Metal Headless Node Provisioning Script (Debian / Ubuntu)
# Configures power saving, disables lid-close sleep, hardens SSH, installs Docker
# ==============================================================================

set -euo pipefail

echo "===> [1/5] Updating Apt repositories and baseline packages..."
sudo apt-get update -y
sudo apt-get install -y \
    curl \
    wget \
    git \
    htop \
    iotop \
    lm-sensors \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release

echo "===> [2/5] Configuring Systemd power inhibitors (prevent sleep on lid close)..."
# Crucial for repurposed laptop hardware acting as headless 24/7 servers
sudo mkdir -p /etc/systemd/logind.conf.d
cat <<EOF | sudo tee /etc/systemd/logind.conf.d/00-headless-server.conf
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
IdleAction=ignore
EOF

sudo systemctl restart systemd-logind

echo "===> [3/5] Hardening SSH daemon security..."
cat <<EOF | sudo tee /etc/ssh/sshd_config.d/99-hive-hardening.conf
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

sudo systemctl reload ssh || sudo systemctl reload sshd

echo "===> [4/5] Installing Docker Engine & Swarm utilities..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
fi

echo "===> [5/5] Checking Tailscale Mesh VPN..."
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "Tailscale installed. Run 'sudo tailscale up --ssh' to join mesh network."
fi

echo "===> Provisioning completed successfully!"
