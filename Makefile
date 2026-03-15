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

create-admin: ## make create-admin email=you@example.com password=secret username=YourName
	@test -n "$(email)"    || (echo "Usage: make create-admin email=you@example.com password=secret username=YourName"; exit 1)
	@test -n "$(password)" || (echo "Usage: make create-admin email=you@example.com password=secret username=YourName"; exit 1)
	@test -n "$(username)" || (echo "Usage: make create-admin email=you@example.com password=secret username=YourName"; exit 1)
	@set -e; \
	SERVICE_KEY=$$(grep '^SUPABASE_SERVICE_ROLE_KEY=' .env | cut -d= -f2); \
	RESPONSE=$$(curl -s -X POST 'http://localhost:54321/auth/v1/admin/users' \
	  -H "apikey: $$SERVICE_KEY" \
	  -H "Authorization: Bearer $$SERVICE_KEY" \
	  -H "Content-Type: application/json" \
	  -d "{\"email\":\"$(email)\",\"password\":\"$(password)\",\"email_confirm\":true}"); \
	USER_ID=$$(echo "$$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//g'); \
	test -n "$$USER_ID" || (echo "Failed to create user. Response: $$RESPONSE"; exit 1); \
	curl -s -X PATCH "http://localhost:54321/rest/v1/profiles?id=eq.$$USER_ID" \
	  -H "apikey: $$SERVICE_KEY" \
	  -H "Authorization: Bearer $$SERVICE_KEY" \
	  -H "Content-Type: application/json" \
	  -H "Prefer: return=minimal" \
	  -d "{\"username\":\"$(username)\",\"role\":\"admin\"}"; \
	echo ""; \
	echo "✓ Account created: $(email)  (id: $$USER_ID)"
