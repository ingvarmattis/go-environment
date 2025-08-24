.PHONY: help init-swarm deploy deploy-local status logs clean

# Variables
STACK_NAME = go-environment
COMPOSE_FILE = docker/docker-swarm.yaml

help: ## Show help
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init-swarm: ## Initialize Docker Swarm on server
	@echo "🚀 Initializing Docker Swarm..."
	@chmod +x scripts/init-swarm.sh
	@./scripts/init-swarm.sh

deploy: ## Deploy to server via GitHub Actions
	@echo "🚀 Starting deployment via GitHub Actions..."
	@echo "Go to Actions section in GitHub and run workflow 'Deploy to Home Server'"

deploy-local: ## Local deployment (for testing)
	@echo "🚀 Local Docker Swarm deployment..."
	@if [ ! -f .env ]; then \
		echo "❌ .env file not found. Creating example .env file..."; \
		cp .env.example .env; \
		echo "⚠️  Please edit .env file with your actual values before running deploy-local"; \
		exit 1; \
	fi
	@chmod +x scripts/deploy-with-env.sh
	@./scripts/deploy-with-env.sh

deploy-env: ## Deploy using environment variables from .env file
	@echo "🚀 Deploying with environment variables..."
	@chmod +x scripts/deploy-with-env.sh
	@./scripts/deploy-with-env.sh

status: ## Show services status
	@echo "📊 Docker Swarm services status:"
	docker stack services $(STACK_NAME)

logs: ## Show services logs
	@echo "📝 Services logs:"
	@echo "Use: docker service logs <service-name>"
	@echo "Available services:"
	docker stack services $(STACK_NAME) --format "table {{.Name}}"

clean: ## Stop and remove stack
	@echo "🧹 Stopping and removing stack..."
	docker stack rm $(STACK_NAME) || true

restart: clean deploy-env ## Restart stack

ps: ## Show running containers
	@echo "🐳 Running containers:"
	docker stack ps $(STACK_NAME)

monitor: ## Real-time monitoring
	@echo "📈 Services monitoring (Ctrl+C to exit):"
	watch -n 2 'docker stack services $(STACK_NAME)'

backup: ## Create data backup
	@echo "💾 Creating data backup..."
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@echo "Backup created in backups/ folder"

install-deps: ## Install dependencies on server
	@echo "📦 Installing dependencies on server..."
	@echo "Run on server:"
	@echo "sudo apt update && sudo apt install -y docker.io docker-compose"
	@echo "sudo usermod -aG docker $USER"
	@echo "newgrp docker"

create-env: ## Create example .env file
	@echo "📝 Creating example .env file..."
	@if [ -f .env.example ]; then \
		cp .env.example .env; \
		echo "✅ .env file created from .env.example"; \
		echo "⚠️  Please edit .env file with your actual values"; \
	else \
		echo "❌ .env.example file not found"; \
		echo "Creating basic .env file..."; \
		cat > .env << EOF; \
GRAFANA_ADMIN_PASSWORD=admin
POSTGRES_PASSWORD=postgres
POSTGRES_USER=postgres
POSTGRES_DB=grafana

EOF
		echo "✅ Basic .env file created"; \
		echo "⚠️  Please edit .env file with your actual values"; \
	fi
