.PHONY: build up down restart install logs shell ps clean monitoring backup

build:            ## Build all images
	docker compose build

up:               ## Start the full 3-tier stack
	docker compose up -d

down:             ## Stop the stack
	docker compose down

restart: down up  ## Restart the stack

install:          ## Install Magento inside the php container
	bash scripts/install-magento.sh

logs:             ## Tail logs from all services
	docker compose logs -f

shell:            ## Open a bash shell in the php container
	docker compose exec php bash

ps:               ## Show running containers
	docker compose ps

monitoring:       ## Start the monitoring stack (Prometheus/Grafana/Loki)
	docker compose -f monitoring/docker-compose.monitoring.yml up -d

backup:           ## Run a database + media backup
	bash backups/backup.sh

clean:            ## Stop stack and remove volumes (DELETES DATA)
	docker compose down -v
