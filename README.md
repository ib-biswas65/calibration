# ITE Calibration

Web dashboard for the temperature data logger calibration team: upload
reference-logger CSVs and a calibration workbook, define setpoint windows, and
generate per-logger Japanese calibration certificates (`.docx`) — with history,
audit trail, and user management.

## Documentation

| Doc | Read it when |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | You want to understand the codebase: repo layout, API/engine internals, run lifecycle, data model, environments. |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | **Anything is broken in production**, or you're about to rebuild/redeploy. Covers the Windows Docker deployment, why source edits don't affect running containers, the debugging order, and incident history. |
| [scripts/README.md](scripts/README.md) | You need the one-shot historical-data migration scripts. |
| `docs/superpowers/` | Historical design specs and implementation plans. |

## Repo layout

- `apps/api/` — FastAPI service (Python 3.12) + calibration engine
- `apps/web/` — Vite + React + TypeScript SPA
- `infra/` — Docker Compose for local dev (builds from source)
- `deploy-package/` — what ships to the production Windows PC (pre-baked images)
- `scripts/` — one-shot operational scripts

There is no desktop app. An earlier Flet-based prototype was removed
2026-08-14 — the web dashboard replaced it.

## Features

- **Login** — email + password, httpOnly cookie sessions, lockout after 10 failures.
- **Overview** — stat tiles (loggers, runs, pass rate, overdue), recent runs, due-soon rails.
- **New Calibration** — multi-step form: batch info → upload N reference CSVs +
  1 calibration XLSX → configure setpoint windows → generate certificates in the
  background, poll until done, zip download.
- **History / Run Detail** — searchable run list; per-run tabs for loggers
  (per-setpoint deviations), setpoints, file checksums, and audit trail;
  per-certificate `.docx` download; date editing with automatic certificate
  regeneration; manual deviation correction.
- **Admin / Users** — invite (one-time setup link), roles, enable/disable.
- **CLI** — `ite-api run-calibration` for batch generation without the UI.

## Quickstart (local dev)

Prerequisites: Docker, Docker Compose v2.

```bash
cd infra
cp .env.example .env       # edit POSTGRES_PASSWORD before any real use
docker compose --env-file .env up -d --build
curl http://localhost/api/health
```

First-time setup — apply migrations and create the first admin:

```bash
docker compose -f infra/docker-compose.yml --env-file infra/.env exec api alembic upgrade head
docker compose -f infra/docker-compose.yml --env-file infra/.env exec api \
  ite-api create-admin --email you@ite.local --full-name "You" --password "at-least-twelve-chars"
```

Then log in at http://localhost/login.

## Local dev without Docker

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

### End-to-end tests

```bash
cd infra && docker compose --env-file .env up -d --build
# (apply migration + create admin as above)
cd apps/web && BASE_URL=http://localhost npm run e2e
```

## Production

The production Windows PC runs pre-baked images via
`deploy-package/docker-compose.yml`. **Do not debug production from this
README** — read [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) first; it exists
because the deployment has non-obvious failure modes that have burned us
before.
