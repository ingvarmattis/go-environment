#Docker Swarm
local-env-up:
	docker stack deploy -c docker-swarm.yaml env

local-env-down:
	docker stack rm env

#Local directory
	grafana_data  loki_data  postgres_data  prometheus_data  promtail_data  tempo_data

#Create Directories
DATA_DIR := /data/fast

.PHONY: create-directories

create-directories:
	@echo "Creation directories in $(DATA_DIR)..."

	# grafana_data
	mkdir -p $(DATA_DIR)/grafana_data
	chmod 755 $(DATA_DIR)/grafana_data
	chown 472:472 $(DATA_DIR)/grafana_data

	# loki_data
	mkdir -p $(DATA_DIR)/loki_data
	chmod 775 $(DATA_DIR)/loki_data
	chown 10001:10001 $(DATA_DIR)/loki_data

	# postgres_data
	mkdir -p $(DATA_DIR)/postgres_data
	chmod 700 $(DATA_DIR)/postgres_data
	chown 999:root $(DATA_DIR)/postgres_data

	# prometheus_data
	mkdir -p $(DATA_DIR)/prometheus_data
	chmod 755 $(DATA_DIR)/prometheus_data
	chown nobody:nogroup $(DATA_DIR)/prometheus_data

	# promtail_data
	mkdir -p $(DATA_DIR)/promtail_data
	chmod 755 $(DATA_DIR)/promtail_data
	chown root:root $(DATA_DIR)/promtail_data

	# tempo_data
	mkdir -p $(DATA_DIR)/tempo_data
	chmod 755 $(DATA_DIR)/tempo_data
	chown 10001:10001 $(DATA_DIR)/tempo_data

	@echo "All directories have been created."
