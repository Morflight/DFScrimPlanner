# Troubleshooting

> Populate as issues and solutions are discovered.

## Intermittent 404s or wrong container responding to requests

**Symptom:** Requests randomly fail or hit the wrong app (e.g. a PHP error from a different project).

**Cause:** All containers share the `reverse-proxy` Docker network. If two projects define a service with the same generic name (e.g. `php`, `db`, `database`), Docker DNS round-robins between them — so requests randomly hit the wrong container.

**Fix:** Always use the **container name** (not the service name) in config files:
- In `nginx/default.conf`: `fastcgi_pass <prefix>_php:9000;` — never `fastcgi_pass php:9000;`
- In `.env` / `DATABASE_URL`: use `<prefix>_db` — never `db` or `database`

Then restart the affected container: `docker restart <container_name>`

> This is enforced by the Docker naming rule in the workspace `CLAUDE.md` — always prefix container names with the project prefix.
