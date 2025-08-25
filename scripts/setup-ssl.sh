#!/bin/bash

echo "🔒 Setting up SSL certificate for moving.mattis.dev"

# Install certbot if not installed
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    sudo apt update
    sudo apt install -y certbot
fi

# Stop nginx temporarily to free port 80
echo "Stopping go-environment stack temporarily..."
docker stack rm go-environment || true
sleep 15

# Get SSL certificate using standalone mode
echo "Getting SSL certificate..."
sudo certbot certonly \
    --standalone \
    --agree-tos \
    --no-eff-email \
    --email admin@mattis.dev \
    -d moving.mattis.dev

if [ $? -eq 0 ]; then
    echo "✅ SSL certificate obtained successfully!"
    echo "Certificate location: /etc/letsencrypt/live/moving.mattis.dev/"
    
    # Set proper permissions
    sudo chmod -R 755 /etc/letsencrypt/live/
    sudo chmod -R 755 /etc/letsencrypt/archive/
    
    echo "📋 Certificate files:"
    sudo ls -la /etc/letsencrypt/live/moving.mattis.dev/
else
    echo "❌ Failed to obtain SSL certificate"
    exit 1
fi

echo ""
echo "🚀 Now restart go-environment stack with SSL support:"
echo "./scripts/deploy-with-env.sh"
