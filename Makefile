dev:
	supabase start
	docker compose -f docker-compose.dev.yml up -d

stop:
	docker compose -f docker-compose.dev.yml down
	supabase stop

test:
	npx vitest run

build:
	npx vite build

deploy:
	git push origin master

types:
	supabase gen types typescript --local > src/lib/types/database.ts

migration:
	supabase migration new $(name)

db-reset:
	supabase db reset
