#!/bin/bash

# Script for initializing Docker Swarm on Debian 12 home server
# Run with root privileges or user with docker rights

set -e

echo "🚀 Initializing Docker Swarm on Debian 12..."

# Check Debian version
if [[ -f /etc/debian_version ]]; then
    DEBIAN_VERSION=$(cat /etc/debian_version | cut -d. -f1)
    echo "📋 Debian version: $(cat /etc/debian_version)"
    
    if [[ $DEBIAN_VERSION -lt 12 ]]; then
        echo "⚠️  Warning: Debian 12 or higher is recommended"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo "⚠️  Could not determine Debian version"
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Run scripts/setup-server.sh first"
    exit 1
fi

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    echo "🔄 Starting Docker..."
    sudo systemctl start docker
fi

# Check if swarm is already initialized
if docker info | grep -q "Swarm: active"; then
    echo "✅ Docker Swarm is already initialized"
    
    # Show current swarm information
    echo "📊 Current swarm information:"
    docker info | grep -A 10 "Swarm:"
    
    read -p "Reinitialize swarm? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Stopping current swarm..."
        docker swarm leave --force
        echo "✅ Swarm stopped"
    else
        echo "✅ Using existing swarm"
        exit 0
    fi
fi

# Get IP address for swarm
echo "🌐 Determining IP address for swarm..."
SWARM_IP=$(hostname -I | awk '{print $1}')
echo "📍 Using IP address: $SWARM_IP"

# Initialize Docker Swarm
echo "🔄 Initializing Docker Swarm..."
docker swarm init --advertise-addr $SWARM_IP

# Create necessary data directories
echo "📁 Creating data directories..."
sudo mkdir -p /data/fast/{prometheus_data,grafana_data,postgres_data,tempo_data,technitium-dns-data/zones,torrserver_data,torrserver_cache}

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R 1000:1000 /data/fast/

# Create overlay network for services
echo "🌐 Creating overlay network..."
docker network create --driver overlay --attachable go-environment-network || echo "Network already exists"

# Create config for Docker daemon optimizations
echo "⚙️ Setting up Docker daemon for Debian 12..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "experimental": false,
  "metrics-addr": "127.0.0.1:9323",
  "live-restore": true,
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5
}
EOF

# Restart Docker to apply settings
echo "🔄 Restarting Docker to apply settings..."
sudo systemctl restart docker

# Wait for Docker to start
echo "⏳ Waiting for Docker to start..."
sleep 10

# Check swarm status
echo "✅ Checking swarm status..."
docker info | grep -A 5 "Swarm:"

# Show tokens for joining other nodes
echo ""
echo "🔑 Tokens for joining other nodes:"
echo "Manager token:"
docker swarm join-token manager -q
echo ""
echo "Worker token:"
docker swarm join-token worker -q

echo ""
echo "✅ Docker Swarm initialization completed!"
echo ""
echo "📋 Next steps:"
echo "1. Copy SSH key to server: ssh-copy-id username@your-server-ip"
echo "2. Setup GitHub Secrets in repository"
echo "3. Run deployment via GitHub Actions"
echo ""
echo "🌐 Swarm IP: $SWARM_IP"
echo "🔑 Manager token: $(docker swarm join-token manager -q)"
echo "🔑 Worker token: $(docker swarm join-token worker -q)"
