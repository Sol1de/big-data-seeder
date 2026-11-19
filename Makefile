DB ?= seeder
SCALE ?= 1
PSQL = docker compose exec -T postgres psql -U postgres -v ON_ERROR_STOP=1

.DEFAULT_GOAL := help
.PHONY: help up build down db-drop db-create db-reset migrate seed

help: ## Show available commands
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

up: ## Start the postgres container
	docker compose up -d

build: ## Pull the postgres image
	docker compose pull

down: ## Stop and remove the container
	docker compose down

db-drop: ## Drop the database
	$(PSQL) -d postgres -c 'DROP DATABASE IF EXISTS $(DB) WITH (FORCE)'

db-create: ## Create an empty database
	$(PSQL) -d postgres -c 'CREATE DATABASE $(DB)'

db-reset: db-drop db-create ## Drop then create the database

migrate: ## Apply migrations to an empty database
	cat migrations/*.sql | $(PSQL) -d $(DB) -1 -q

seed: db-reset migrate ## Reset the database, migrate, then load seeders
	cat seeders/*.sql | $(PSQL) -d $(DB) -1 -q -v scale=$(SCALE)
