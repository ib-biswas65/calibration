# ITE Calibration

Web dashboard for the temperature data logger calibration team.

This repo is a monorepo:

- `apps/api/` — FastAPI service (Python 3.12)
- `apps/web/` — Vite + React + TypeScript SPA
- `infra/`   — Docker Compose stack (edge nginx + api + web + postgres)
- `docs/superpowers/` — design specs and implementation plans

The legacy Flet desktop prototype lives in `src/` and `Old Method/` and is **not** part of the build.

## Slice 2 (current): Calibration engine (CLI only)

What works after this slice:

- Everything from Slice 1.
- New CLI: `ite-api run-calibration --workbook <xlsx> [--workbook <xlsx> ...] --reference <csv> [--reference <csv> ...] --template <docx> --output <dir> --test-date-jp 2026年4月14日 --doc-date-jp 2026年4月15日`
- Output is one `.docx` certificate per sheet across all workbooks, written to `<dir>/`.
- Supports any number of reference loggers (CSVs concatenated) and calibration workbooks.

What doesn't work yet: no HTTP routes, no UI for triggering runs. Those arrive in Slice 3.

## Engine smoke test

```bash
cd apps/api
.venv/bin/ite-api run-calibration \
  --workbook tests/fixtures/calibration/workbook.xlsx \
  --reference tests/fixtures/calibration/reference.csv \
  --template tests/fixtures/calibration/template.docx \
  --output /tmp/ite-out \
  --start-cert-no 0000001720 \
  --test-date-jp 2026年4月14日 \
  --doc-date-jp 2026年4月15日
ls /tmp/ite-out/
```

## Slice 1: Auth + AppShell

What works after this slice:

- Admin user created via CLI: `ite-api create-admin --email ... --full-name ... --password ...`
- Login at `http://localhost/login` (email + password), session cookies set.
- Authenticated routes show the AppShell (green sidebar + topbar) with placeholder pages.
- `GET /api/auth/me` returns the current user; logout revokes the session.
- Refresh middleware silently rotates the access token when it expires.
- Lockout after 10 failed logins per email in 15 min.
- Origin header check on all mutating routes.
- CI runs lint + tests for both apps (api tests use `testcontainers` Postgres).

## First-time setup

After `docker compose up`, apply migrations and create the first admin:

```bash
docker compose -f infra/docker-compose.yml --env-file infra/.env exec api alembic upgrade head
docker compose -f infra/docker-compose.yml --env-file infra/.env exec api \
  ite-api create-admin --email you@ite.local --full-name "You" --password "at-least-twelve-chars"
```

Then log in at http://localhost/login.

## End-to-end tests

```bash
cd infra && docker compose --env-file .env up -d --build
# (apply migration + create admin as above)
cd apps/web && BASE_URL=http://localhost npm run e2e
cd ../../infra && docker compose --env-file .env down
```

## Quickstart

Prerequisites: Docker, Docker Compose v2.

```bash
cd infra
cp .env.example .env       # edit POSTGRES_PASSWORD before any real use
docker compose --env-file .env up -d --build
curl http://localhost/api/health
open http://localhost/     # or: xdg-open / start
docker compose --env-file .env down
```

## Local dev (without Docker)

### API

```bash
cd apps/api
python3.12 -m venv .venv
.venv/bin/pip install -e ".[dev]"
.venv/bin/pytest -v
.venv/bin/uvicorn ite_api.main:app --reload
```

### Web

```bash
cd apps/web
npm install
npm test
npm run dev      # http://localhost:5173, proxies /api to :8000
```
