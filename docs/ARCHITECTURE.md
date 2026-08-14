# Architecture

ITE Calibration is a web dashboard for a temperature-logger calibration team.
Users upload reference-logger CSVs and a calibration workbook, define setpoint
time windows, and the system generates Japanese calibration certificates
(`.docx`) per logger, with full history, audit trail, and user management.

```
Browser ──► edge (nginx :80) ──┬──► web  (nginx, serves built React SPA)
                               └──► api  (FastAPI + uvicorn :8000) ──► postgres
                                        └──► data volume (/var/lib/ite-calibration/data)
```

## Repository layout

| Path | What it is |
|---|---|
| `apps/api/` | FastAPI service, Python 3.12. The calibration engine lives here. |
| `apps/web/` | Vite + React + TypeScript SPA. |
| `infra/` | Docker Compose for **local development** (builds from source) + shared `nginx.conf`. |
| `deploy-package/` | What ships to the production Windows PC (prod compose, setup/backup scripts, seed DB). See `docs/DEPLOYMENT.md`. |
| `scripts/` | One-shot operational/migration scripts (historical data ingestion). Not part of the runtime. |
| `docs/superpowers/` | Design specs and implementation plans (historical record). |
| `.github/workflows/` | `ci.yml` (lint + test both apps) and `deploy.yml` (auto-deploy via self-hosted runner — see DEPLOYMENT.md before touching). |
| `register-task.ps1` | Registers the Windows Task Scheduler job for daily DB/volume backups. |

## API (`apps/api/ite_api/`)

- `main.py` — app factory; wires middleware + routers; on startup runs alembic
  migrations (in Docker) and resets runs stuck in `processing` from a crash.
- `config.py` — pydantic-settings; all env vars use the `ITE_` prefix
  (`ITE_DATABASE_URL`, `ITE_JWT_SECRET`, `ITE_DATA_DIR`, `ITE_ALLOWED_ORIGINS`).
- `routes/`
  - `auth.py` — login/logout/me, password reset. httpOnly cookie sessions
    (access `ite_at` 15 min, refresh `ite_rt` 14 days), lockout after 10
    failures / 15 min.
  - `runs.py` — the core workflow (see "Run lifecycle" below), plus
    certificate download (single `.docx` / zip), date editing with cert
    regeneration, and manual deviation correction.
  - `loggers.py`, `overview.py`, `users.py` — logger registry, dashboard
    stats, admin user management (invite → one-time setup link).
- `auth/` — password hashing (argon2), JWT tokens, role dependencies
  (`admin` > `engineer` > `viewer`), lockout bookkeeping.
- `middleware/` — Origin header check on mutating requests; silent
  access-token refresh.
- `db/models/` — SQLAlchemy models: `User`, `Session`, `PasswordReset`,
  `AuditLog`, and the calibration trio `CalibrationRun` / `LoggerResult` /
  `Logger` (+ file-attachment tables `RunReferenceFile`, `RunCalibrationFile`).
- `calibration/` — the engine (pure functions, no DB):
  - `ref_loader.py` — parses reference-logger CSVs. Auto-detects two formats
    (`mc3000`: datetime first field; `indexed`: index,datetime,temp) and
    Japanese encodings (Shift-JIS/cp932/UTF-8). **Timestamps may be
    non-zero-padded and secondless** (`2026/8/10 16:56`) — the parser accepts
    both padded and unpadded forms.
  - `cal_loader.py` — loads the multi-sheet calibration `.xlsx` (one sheet per
    logger under test).
  - `matcher.py` — for each setpoint window, finds the closest-in-time
    ref/cal reading pairs. Logger timestamps are tz-naive; window bounds
    arriving as tz-aware ISO strings are stripped to naive before comparison.
  - `docx_filler.py` + `engine.py` — fill the certificate template
    (`calibration/template.docx`, placeholders documented in
    `engine.RunConfig`) and save one `.docx` per logger.
- `cli.py` — `ite-api create-admin` and `ite-api run-calibration` (batch
  generation without the UI).
- Migrations: `alembic/versions/0001`–`0007`, run automatically on container
  start.

### Run lifecycle

1. `POST /api/runs` — create draft (batch name, dates, threshold).
2. `POST /api/runs/{id}/references` (×N) + `/calibration` (×1) — upload files;
   stored under `data/runs/{id}/` on the volume with checksums recorded.
3. `POST /api/runs/{id}/process` — kicks a FastAPI `BackgroundTask`;
   status: `draft → processing → complete | failed`.
   On failure, `calibration_runs.failure_reason` stores the message **and the
   full traceback** — this is the first place to look, not the container logs.
4. Frontend polls `GET /api/runs/{id}/status`; certificates are then
   downloadable per-logger or as a zip.

## Web (`apps/web/src/`)

- `api/client.ts` — typed fetch wrapper (cookies included, error normalization).
- `auth/` — `AuthProvider` context, `RequireAuth` route guard.
- `pages/` — one component per route: Login, Overview, NewCalibration
  (multi-step form), History, RunDetail (Loggers/Setpoints/Conditions/Audit
  tabs), Loggers + LoggerProfile, AdminUsers, Settings, Register/ResetPassword.
- `components/` — AppShell (sidebar + topbar), DataTable, FileDropZone,
  SetpointWindowRow, StatTile, Toast, ConfirmDialog, etc. CSS Modules +
  design tokens in `theme/tokens.css`.
- Dev server proxies `/api` to `:8000` (`vite.config.ts`). Tests: Vitest
  (unit) and Playwright (`e2e/`, run against the Docker stack).

## Environments

| | dev (`infra/`) | prod (`deploy-package/`) |
|---|---|---|
| Compose file | `infra/docker-compose.yml` | `deploy-package/docker-compose.yml` |
| api/web images | **built from source** (`build:`) | **pre-baked** (`image:` loaded from tar) |
| Env file | `infra/.env` | `deploy-package/.env` |
| nginx config | `infra/nginx.conf` | `deploy-package/nginx.conf` (same content) |

The two nginx.conf copies are intentionally identical; if you change one,
change the other. Everything else that used to be duplicated between `infra/`
and `deploy-package/` was consolidated into `deploy-package/` (2026-08-14).

## Testing

- API: `pytest` in `apps/api/tests/` — pure-unit for the calibration engine,
  `testcontainers` Postgres for route tests. Run: `pip install -e ".[dev]" && pytest`.
- Web: `npm test` (Vitest), `npm run e2e` (Playwright, needs the stack up).
- CI (`.github/workflows/ci.yml`) runs both suites on every push/PR.

## Key operational facts

- Production containers run **baked images** — source edits do nothing until
  you rebuild and recreate the container. Full detail, incident history and
  debugging order: `docs/DEPLOYMENT.md`.
- The source of truth for run failures is the `calibration_runs.failure_reason`
  column, not `docker logs`.
- Daily backups: `deploy-package/backup-windows.ps1` via Task Scheduler
  (registered by `register-task.ps1`), dumping Postgres + the certificate
  volume to `C:\ite-calibration-backups`.
