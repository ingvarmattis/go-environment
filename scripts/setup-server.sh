#!/bin/bash

# Script for quick setup of home server on Debian 12
# Run with root privileges or user with sudo rights

set -e

echo "🚀 Setting up Debian 12 home server for Docker Swarm..."

# Check if script is run as root or with sudo
if [[ $EUID -eq 0 ]]; then
    echo "✅ Script is running with root privileges"
else
    echo "❌ Run script with root privileges or use sudo"
    exit 1
fi

# Check Debian version
DEBIAN_VERSION=$(cat /etc/debian_version | cut -d. -f1)
if [[ $DEBIAN_VERSION -lt 12 ]]; then
    echo "⚠️  Warning: Debian 12 or higher is recommended. Current version: $(cat /etc/debian_version)"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "📦 Updating Debian 12 system..."
apt update && apt upgrade -y

# Install necessary packages for Debian 12
echo "📦 Installing packages for Debian 12..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    git \
    htop \
    tree \
    unzip \
    ufw \
    fail2ban \
    logrotate \
    ntp \
    ntpdate

# Setup NTP for time synchronization
echo "⏰ Setting up NTP..."
systemctl enable ntp
systemctl start ntp
ntpdate -s time.nist.gov

# Install Docker for Debian 12
echo "🐳 Installing Docker for Debian 12..."

# Add official Docker GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list and install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
echo "🐳 Setting up Docker..."
systemctl start docker
systemctl enable docker

# Create user for Docker (if doesn't exist)
DOCKER_USER="docker-user"
if ! id "$DOCKER_USER" &>/dev/null; then
    echo "👤 Creating user $DOCKER_USER..."
    useradd -m -s /bin/bash $DOCKER_USER
    usermod -aG docker $DOCKER_USER
    usermod -aG sudo $DOCKER_USER
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/docker-user
    chmod 440 /etc/sudoers.d/docker-user
else
    echo "✅ User $DOCKER_USER already exists"
    usermod -aG docker $DOCKER_USER
fi

# Create project directories
echo "📁 Creating directories..."
mkdir -p /opt/go-environment
mkdir -p /data/fast/{prometheus_data,grafana_data,postgres_data,tempo_data,technitium-dns-data/zones,torrserver_data,torrserver_cache}

# Set proper permissions
echo "🔐 Setting permissions..."
chown -R $DOCKER_USER:$DOCKER_USER /opt/go-environment
chown -R 1000:1000 /data/fast/

# Setup firewall (ufw) for Debian 12
echo "🔥 Setting up firewall for Debian 12..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 3000/tcp
ufw allow 9090/tcp
ufw allow 3100/tcp
ufw allow 3200/tcp
ufw allow 5778/tcp
ufw allow 53/tcp
ufw allow 53/udp
ufw allow 5380/tcp
ufw --force enable

# Setup fail2ban for SSH protection
echo "🛡️ Setting up fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Create swap file (if needed)
if ! swapon --show | grep -q "/swapfile"; then
    echo "💾 Creating swap file..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "✅ Swap file created"
fi

# Setup system parameters for Debian 12
echo "⚙️ Setting system parameters for Debian 12..."
cat >> /etc/sysctl.conf << EOF

# Docker Swarm optimizations for Debian 12
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
vm.max_map_count = 262144
vm.swappiness = 10
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
EOF

# Apply changes
sysctl -p

# Setup logrotate for Docker
echo "📝 Setting up logrotate for Docker..."
cat > /etc/logrotate.d/docker << EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

# Create systemd service for automatic Docker Swarm startup
echo "🔧 Creating systemd service for Docker Swarm..."
cat > /etc/systemd/system/docker-swarm.service << EOF
[Unit]
Description=Docker Swarm Manager
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker swarm init --advertise-addr \$(hostname -I | awk '{print \$1}')
ExecStop=/usr/bin/docker swarm leave --force
User=$DOCKER_USER
Group=docker
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable docker-swarm.service

# Setup automatic security updates
echo "🔒 Setting up automatic security updates..."
apt install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# Enable automatic updates
systemctl enable unattended-upgrades
systemctl start unattended-upgrades

echo ""
echo "✅ Debian 12 server setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Reboot server: sudo reboot"
echo "2. After reboot check Docker Swarm: docker info | grep Swarm"
echo "3. Clone repository: cd /opt && git clone <your-repo-url> go-environment"
echo "4. Setup GitHub Secrets in repository"
echo "5. Run deployment via GitHub Actions"
echo ""
echo "🔑 User for connection: $DOCKER_USER"
echo "📁 Project directory: /opt/go-environment"
echo "💾 Data directories: /data/fast/"
echo ""
echo "🛡️ Additional security settings:"
echo "- Firewall (ufw) configured and enabled"
echo "- Fail2ban protects SSH from brute force"
echo "- Automatic security updates enabled"
echo "- Logrotate configured for Docker logs"
