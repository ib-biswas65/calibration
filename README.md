# ITE Calibration

Web dashboard for the temperature data logger calibration team.

This repo is a monorepo:

- `apps/api/` — FastAPI service (Python 3.12)
- `apps/web/` — Vite + React + TypeScript SPA
- `infra/`   — Docker Compose stack (edge nginx + api + web + postgres)
- `docs/superpowers/` — design specs and implementation plans

The legacy Flet desktop prototype lives in `src/` and `Old Method/` and is **not** part of the build.

## Slice 0 (current): Skeleton

What works after this slice:

- `docker compose up` brings up Postgres + API + SPA + edge nginx.
- `GET http://localhost/api/health` returns `{"status":"ok"}`.
- `http://localhost/` shows a placeholder page.
- CI runs lint + tests for both apps on every push.

What doesn't work yet: authentication, any pages, any DB tables. Those arrive in Slice 1.

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
