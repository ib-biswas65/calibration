# ITE Calibration

Web dashboard for the temperature data logger calibration team.

This repo is a monorepo:

- `apps/api/` — FastAPI service (Python 3.12)
- `apps/web/` — Vite + React + TypeScript SPA
- `infra/`   — Docker Compose stack (edge nginx + api + web + postgres)
- `docs/superpowers/` — design specs and implementation plans

The legacy Flet desktop prototype lives in `src/` and `Old Method/` and is **not** part of the build.

## What works now (Slices 1–6 complete)

- **Login** — email + password, httpOnly cookie sessions, lockout after 10 failures.
- **Overview** — 4 stat tiles (loggers, runs, pass rate, overdue), recent runs, due-soon rails.
- **New Calibration** — multi-step form: batch info → upload N reference CSVs + 1 calibration XLSX → configure setpoint windows → generate certificates (backend `BackgroundTask`), polling until done, zip download.
- **History** — searchable, filterable run list; table ↔ card view toggle; click → run detail.
- **Run Detail** — 4 tabs: Loggers (per-setpoint deviation cells), Setpoints, Conditions (file checksums), Audit trail. Per-certificate `.docx` download + "download all (.zip)".
- **Admin / Users** — list users, invite (one-time setup link), change role, enable/disable.
- **Engine** — CLI `ite-api run-calibration` for batch generation without the UI.
- **Data** persisted to Postgres + local disk volume (`/var/lib/ite-calibration/data/`).

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
