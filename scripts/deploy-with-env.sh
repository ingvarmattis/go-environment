#!/bin/bash

# Script for deploying Docker Swarm stack with environment variables
# This script should be run on the server after receiving environment variables

set -e

STACK_NAME="go-environment"
COMPOSE_FILE="docker/docker-swarm.yaml"

echo "🚀 Deploying Docker Swarm stack with environment variables..."

# Check if .env file exists
if [[ ! -f .env ]]; then
    echo "❌ .env file not found. Please create it with your environment variables."
    echo "Example .env file:"
    cat << EOF
GRAFANA_ADMIN_PASSWORD=your_secure_password
POSTGRES_PASSWORD=your_secure_password
POSTGRES_USER=postgres
POSTGRES_DB=grafana
GODADDY_DDNS_API_KEY=your_api_key
GODADDY_DDNS_API_SECRET=your_api_secret
GODADDY_DDNS_DOMAIN=your-domain.com
GODADDY_DDNS_INTERVAL=60
EOF
    exit 1
fi

# Load environment variables
echo "📋 Loading environment variables from .env file..."
export $(cat .env | grep -v '^#' | xargs)

# Validate required variables
echo "🔍 Validating required environment variables..."

REQUIRED_VARS=(
    "GRAFANA_ADMIN_PASSWORD"
    "POSTGRES_PASSWORD"
    "GODADDY_DDNS_API_KEY"
    "GODADDY_DDNS_API_SECRET"
    "GODADDY_DDNS_DOMAIN"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "❌ Required environment variable $var is not set"
        exit 1
    else
        echo "✅ $var is set"
    fi
done

# Set defaults for optional variables
export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_DB=${POSTGRES_DB:-grafana}
export GODADDY_DDNS_INTERVAL=${GODADDY_DDNS_INTERVAL:-60}

echo "✅ All environment variables validated"

# Stop existing stack if running
if docker stack ls | grep -q "$STACK_NAME"; then
    echo "🔄 Stopping existing stack $STACK_NAME..."
    docker stack rm "$STACK_NAME" || true
    echo "⏳ Waiting for services to stop..."
    sleep 15
fi

# Deploy new stack
echo "🚀 Deploying new stack $STACK_NAME..."
docker stack deploy -c "$COMPOSE_FILE" "$STACK_NAME"

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check stack status
echo "📊 Checking stack status..."
docker stack services "$STACK_NAME"

# Check service health
echo "🔍 Checking service health..."
for service in $(docker stack services "$STACK_NAME" --format "{{.Name}}"); do
    echo "Checking $service..."
    if docker service ls --filter "name=$service" --format "{{.Replicas}}" | grep -q "0/"; then
        echo "⚠️  $service has 0 replicas running"
    else
        echo "✅ $service is running"
    fi
done

echo ""
echo "🎉 Deployment completed successfully!"
echo "📋 Stack name: $STACK_NAME"
echo "🌐 Services available at:"
echo "   - Grafana: http://localhost:3000"
echo "   - Prometheus: http://localhost:9090"

echo "   - Tempo: http://localhost:5778"
echo ""
echo "📝 To view logs: docker service logs ${STACK_NAME}_<service_name>"
echo "📊 To check status: docker stack services $STACK_NAME"
