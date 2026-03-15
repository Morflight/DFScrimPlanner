export HOST_UID := $(shell id -u)
export HOST_GID := $(shell id -g)
export DOCKER_GID := $(shell getent group docker 2>/dev/null | cut -d: -f3 || echo 999)

SUPABASE = docker compose -f docker-compose.dev.yml run --rm supabase-cli supabase

init:
	docker compose -f docker-compose.dev.yml run --rm app npx sv create .
	$(SUPABASE) init

start:
	$(SUPABASE) start
	docker compose -f docker-compose.dev.yml up -d app

stop:
	docker compose -f docker-compose.dev.yml stop app
	$(SUPABASE) stop

restart:
	docker compose -f docker-compose.dev.yml restart app

test:
	docker compose -f docker-compose.dev.yml exec app npx vitest run

build:
	docker compose -f docker-compose.dev.yml exec app npx vite build

deploy:
	git push origin master

types:
	$(SUPABASE) gen types typescript --local > src/lib/types/database.ts

migration:
	$(SUPABASE) migration new $(name)

db-reset:
	$(SUPABASE) db reset
