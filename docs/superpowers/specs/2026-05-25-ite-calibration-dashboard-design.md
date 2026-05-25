# ITE Calibration — Web Dashboard Design

**Date:** 2026-05-25
**Status:** Approved (sections 1–6)
**Source design bundle:** Claude Design handoff "calibration" (Calibra Dashboard.html, 8 pages, IBM Plex + green-dominant palette)
**Replaces:** the existing Flet desktop app under `src/` (kept in place but not used by the new build)

---

## 1. Architecture & repo layout

Three-tier system, all running on one LAN server via Docker Compose:

```
[ Browser ] ──HTTP(S)──▶ [ Nginx ] ──▶ [ React SPA (static) ]
                                  └──▶ [ FastAPI ] ──▶ [ Postgres ]
                                                  └──▶ [ /data volume ]
```

**Repo layout (monorepo):**

```
ite-calibration/
├── apps/
│   ├── api/                  # FastAPI service
│   │   ├── ite_api/
│   │   │   ├── main.py
│   │   │   ├── auth/         # email+password, argon2, JWT sessions
│   │   │   ├── db/           # SQLAlchemy models + Alembic migrations
│   │   │   ├── routes/       # /auth, /runs, /loggers, /uploads, /overview
│   │   │   ├── calibration/  # NEW engine: ref_loader, cal_loader, matcher, docx_filler
│   │   │   ├── storage/      # local-disk file store abstraction
│   │   │   └── cli.py        # create-admin, run-calibration (dev)
│   │   ├── tests/
│   │   └── pyproject.toml
│   └── web/                  # Vite + React + TS SPA
│       ├── src/
│       │   ├── api/          # typed client (openapi-typescript)
│       │   ├── auth/
│       │   ├── components/
│       │   ├── pages/
│       │   ├── theme/        # tokens.css (IBM Plex, green-dominant)
│       │   └── main.tsx
│       └── package.json
├── infra/
│   ├── docker-compose.yml    # api + web (nginx) + postgres
│   ├── nginx.conf
│   └── Dockerfile.{api,web}
├── docs/
│   └── superpowers/specs/2026-05-25-ite-calibration-dashboard-design.md
└── README.md
```

**Key choices:**

- One repo, two apps, shared docs/infra.
- The current `src/` Flet code is **not reused**. Per user decision, the new engine is built fresh inside `apps/api/ite_api/calibration/`. The old tree remains untouched for reference and can be moved to `legacy/` or deleted when the new app reaches parity.
- Frontend is a pure static bundle served by nginx; nginx also reverse-proxies `/api/*` to FastAPI. Same-origin, no CORS.

---

## 2. Database schema (Postgres)

Designed for the v1 MVP (Login, Overview, New Calibration, History, Run Detail) with room for the deferred pages (Logger profile, Upcoming/due, Settings) without migrations later.

```sql
users
  id              uuid pk
  email           citext unique not null
  password_hash   text not null              -- argon2id
  full_name       text not null
  role            text not null              -- 'admin' | 'engineer' | 'viewer'
  disabled        boolean not null default false
  created_at      timestamptz default now()
  last_login_at   timestamptz

sessions                                     -- refresh tokens (hashed)
  id              uuid pk
  user_id         uuid fk users
  token_hash      text unique not null
  expires_at      timestamptz not null
  created_at      timestamptz default now()
  revoked_at      timestamptz

password_resets
  id              uuid pk
  user_id         uuid fk users
  token_hash      text unique not null
  expires_at      timestamptz not null
  used_at         timestamptz

loggers
  id              uuid pk
  serial_no       text unique not null
  model           text
  notes           text
  next_due_at     date
  created_at      timestamptz default now()

calibration_runs
  id              uuid pk
  batch_name      text not null
  status          text not null              -- 'draft' | 'processing' | 'complete' | 'failed'
  testing_start   timestamptz not null
  testing_end     timestamptz not null
  certificate_date date not null
  threshold_c     numeric(5,3) not null
  setpoints       jsonb not null             -- [{target_c, start_at, end_at}, ...]
  template_path   text
  failure_reason  jsonb                       -- populated when status='failed'
  created_by      uuid fk users
  created_at      timestamptz default now()
  completed_at    timestamptz

run_reference_files
  id              uuid pk
  run_id          uuid fk calibration_runs on delete cascade
  original_name   text not null
  stored_path     text not null
  sha256          text not null
  uploaded_at     timestamptz default now()

run_calibration_file
  id              uuid pk
  run_id          uuid fk calibration_runs unique
  original_name   text not null
  stored_path     text not null
  sha256          text not null
  uploaded_at     timestamptz default now()

logger_results
  id              uuid pk
  run_id          uuid fk calibration_runs on delete cascade
  logger_id       uuid fk loggers
  sheet_name      text not null
  verdict         text not null              -- 'pass' | 'fail' | 'adjusted'
  max_deviation_c numeric(6,3)
  per_setpoint    jsonb not null             -- [{target_c, ref_c, cal_c, dev_c, within_tol}, ...]
  cert_no         text
  cert_path       text
  created_at      timestamptz default now()

audit_log
  id              bigserial pk
  user_id         uuid fk users
  run_id          uuid fk calibration_runs
  action          text not null              -- 'run.created', 'run.completed', ...
  detail          jsonb
  at              timestamptz default now()
```

**Indexes:** `calibration_runs(created_at desc)`, `logger_results(run_id)`, `logger_results(logger_id, created_at desc)` (for the deferred Logger profile drift chart).

**Rationale:**

- `setpoints` and `per_setpoint` as JSONB — always read/written together with the parent row; small fixed count (3); avoids joins on every list view.
- `loggers` is its own table so the same physical device tracked across many runs shows one drift history.
- `audit_log` is append-only and drives the Run Detail "Audit trail" tab.
- DB stores file path + sha256; files live on disk.

**Migrations:** Alembic, autogenerate from SQLAlchemy models.

---

## 3. API surface (FastAPI)

All routes JSON, prefixed `/api`, same-origin behind nginx. Auth via httpOnly session cookies.

### Auth

```
POST   /api/auth/login            {email, password} → 204 + Set-Cookie
POST   /api/auth/logout           → 204
GET    /api/auth/me               → {id, email, full_name, role}
POST   /api/auth/users            (admin) invite/create user
PATCH  /api/auth/users/{id}       (admin) role / disable
```

### Overview

```
GET    /api/overview              →
  {
    fleet: { total_loggers, due_30d, overdue },
    last_30d: { runs, pass_rate, fail_count, adjusted_count },
    recent_runs: [ {id, batch_name, status, verdict_mix, created_at} × 5 ],
    due_soon:    [ {logger_id, serial_no, next_due_at} × 5 ]
  }
```

One endpoint, one query plan — dashboard is read-heavy; avoid N+1.

### Calibration runs

```
GET    /api/runs?status=&from=&to=&q=&cursor=&limit=50
       → { items: [...], next_cursor }
POST   /api/runs                  create draft from form fields
GET    /api/runs/{id}             full run + logger_results + files
PATCH  /api/runs/{id}             edit (only while status='draft')
DELETE /api/runs/{id}             admin only; cascades files
```

### File uploads (attached to a draft run)

```
POST   /api/runs/{id}/references  multipart, repeatable → {file_id, sha256}
POST   /api/runs/{id}/calibration multipart, single XLSX → {file_id, sheets:[...]}
DELETE /api/runs/{id}/files/{file_id}
```

Calibration upload response previews detected sheet names so the UI can show "X loggers found" before processing.

### Run processing

```
POST   /api/runs/{id}/process     → 202 + {job_id}
GET    /api/runs/{id}/status      → {status, progress, message}
```

Runs in a FastAPI `BackgroundTask` for v1. Swap to RQ/Celery later without API change.

### Results & certificates

```
GET    /api/runs/{id}/results
GET    /api/runs/{id}/results/{result_id}/certificate     → streams .docx
GET    /api/runs/{id}/results.zip                          → all certs as a zip
```

### Loggers (stubs in v1, surfaced in later releases)

```
GET    /api/loggers?q=&cursor=
GET    /api/loggers/{id}                                   → device + history[]
```

**Cross-cutting:**

- All mutating routes require role ≥ `engineer`. `viewer` is read-only. `admin` adds user mgmt + delete.
- Errors: RFC 7807 `application/problem+json`.
- Validation via Pydantic.
- Every state change writes an `audit_log` row.

---

## 4. Frontend structure & design tokens

### Stack

- Vite + React 18 + TypeScript
- React Router v6
- TanStack Query (caching, background refetch)
- React Hook Form + Zod (form schemas)
- Plain CSS modules + CSS variables (matches design prototype's approach)
- lucide-react icons
- Typed API client via `openapi-typescript` from FastAPI's `/openapi.json` (committed)

### Folder layout (`apps/web/src/`)

```
src/
├── main.tsx                # Router + QueryClient + AuthProvider
├── api/
│   ├── client.ts           # fetch wrapper, 401 → /login redirect
│   └── generated/          # openapi-typescript output
├── auth/
│   ├── AuthProvider.tsx    # holds {user, role}; <RequireAuth> guard
│   └── useAuth.ts
├── theme/
│   ├── tokens.css          # all design tokens
│   └── reset.css
├── components/
│   ├── AppShell.tsx        # sidebar + topbar + outlet
│   ├── Sidebar.tsx
│   ├── Topbar.tsx
│   ├── StatTile.tsx        # numeric tile (NO sparkline — per chat decision)
│   ├── DataTable.tsx
│   ├── StatusPill.tsx
│   ├── FileDropZone.tsx
│   ├── SetpointWindowRow.tsx  # two datetime-local pickers + duration label
│   └── Toast.tsx
├── pages/
│   ├── LoginPage.tsx
│   ├── OverviewPage.tsx
│   ├── NewCalibrationPage.tsx   # single-page, all fields visible
│   ├── HistoryPage.tsx          # table ↔ cards toggle (per chat)
│   └── RunDetailPage.tsx        # tabs: Loggers · Setpoints · Conditions · Audit
└── lib/
    ├── format.ts           # temperature, duration, dates (JP-aware)
    └── verdict.ts
```

Deferred pages (Upcoming/due, Logger profile, Certificate viewer, Settings) get "Coming soon" route stubs so the sidebar renders the full nav from day one.

### Design tokens — green-dominant palette

Per the chat, the design must be **majorly green**, with blue/yellow/red used sparingly for semantic states.

```css
:root {
  /* Brand — green-dominant */
  --c-accent-50:  #ecfdf5;
  --c-accent-100: #d1fae5;
  --c-accent-300: #6ee7b7;
  --c-accent-500: #10b981;
  --c-accent-600: #059669;
  --c-accent-700: #047857;
  --c-accent-900: #064e3b;

  /* Neutrals */
  --c-bg:        #f7faf9;
  --c-surface:   #ffffff;
  --c-border:    #e5ebe9;
  --c-text:      #0f1f1a;
  --c-text-soft: #5a6b66;
  --c-text-mute: #8a9994;

  /* Semantic — used sparingly */
  --c-pass: var(--c-accent-600);
  --c-warn: #d97706;
  --c-fail: #b91c1c;
  --c-info: #1d4ed8;

  /* Type */
  --font-sans: "IBM Plex Sans", "Segoe UI", "San Francisco", system-ui, sans-serif;
  --font-mono: "IBM Plex Mono", ui-monospace, monospace;

  /* Scale (8pt) */
  --s-1:4px; --s-2:8px; --s-3:12px; --s-4:16px;
  --s-5:24px; --s-6:32px; --s-8:48px;

  --radius-sm:4px; --radius-md:6px; --radius-lg:10px;
  --shadow-1: 0 1px 2px rgba(15,31,26,.06);
  --shadow-2: 0 4px 12px rgba(15,31,26,.08);
}
```

**Color discipline:**

- Green is the chrome — sidebar accents, active states, primary buttons, "pass" pills, monochromatic charts.
- Blue/yellow/red appear **only** as semantic state (info badge, "adjusted", "fail/overdue"). Never decoration.
- Surfaces stay neutral; backgrounds are not tinted green.

### Per-page notes

- **Login** — centered card, email/password, error toast on 401.
- **Overview** — 4 stat tiles **without sparklines** (Total loggers · Last-30d runs · Pass rate · Overdue), "Recent runs" rail, "Due soon" rail. One `GET /overview`.
- **New Calibration** — single page, all fields visible: Batch info → Reference loggers (multi-file drop) → Calibration workbook (single, shows detected sheets) → Setpoint windows (each row = two `datetime-local` inputs spanning days, adaptive duration label) → Threshold → "Generate certificates" → progress panel polling `/status`.
- **History** — `DataTable` with filter bar (status, date range, search). Toggle to card view (per chat tweak). Row click → Run Detail.
- **Run Detail** — header (batch + status pill), tabs: Loggers (per-setpoint deviation cells), Setpoints, Conditions (file checksums + uploader), Audit trail. "Download all certs (.zip)" button.

### Relationship to the design prototype

We do **not** ship the prototype's "React via Babel in browser" approach. We rebuild the same visual output as proper TS components compiled by Vite. The prototype's `styles.css` and JSX serve as the visual reference for spacing, borders, type sizes.

---

## 5. Auth flow, security & file handling

### Session model

Two-token pattern, cookie-based:

- **Access token** — short-lived JWT (15 min), `httpOnly` + `Secure` + `SameSite=Lax` cookie `ite_at`. Carries `{user_id, role, exp}`.
- **Refresh token** — opaque random 256-bit string, `httpOnly` cookie `ite_rt`, 14-day expiry. Server stores **only** `sha256(token)` in `sessions`.

**Flow:**

```
POST /auth/login → argon2id verify → insert sessions row → set ite_at + ite_rt → 204

Any /api/* → middleware verifies ite_at
   if expired and ite_rt valid → rotate (new ite_at, rotate ite_rt, update sessions)
   else → 401; client redirects to /login

POST /auth/logout → revoke sessions row, clear cookies
```

**Why this shape:**

- httpOnly cookies → XSS cannot steal tokens.
- Refresh-token rotation → stolen RT usable for at most one rotation window before detection.
- Same-origin → `SameSite=Lax` is sufficient; we still enforce `Origin` header on mutating routes as defense-in-depth.

### Password & user lifecycle

- **Hashing:** argon2id (`argon2-cffi`), `t=3, m=64MB, p=4`.
- **No public signup.** Admins create users; API generates a one-time setup link (`password_resets`, 24h). For v1 LAN deployment without SMTP, the link is shown to the admin to share manually.
- **Password policy:** min 12 chars, zxcvbn score ≥ 3, no rotation requirement (NIST 800-63B).
- **Lockout:** 10 failed logins per email in 15 min → 15-min cooldown. Logged.

### Roles

Enforced server-side via a FastAPI dependency on every route:

```
admin    → everything, including user mgmt + run delete
engineer → create/edit own draft runs, process runs, download certs
viewer   → read-only on all runs and overview
```

Frontend hides controls the role can't use; the server is the source of truth.

### File upload safety

- **Size limits:** references ≤ 10 MB each, calibration workbook ≤ 50 MB, total per run ≤ 200 MB. Enforced by nginx and re-checked in FastAPI.
- **Allowlist:** `.csv` for references (text/csv, text/plain), `.xlsx` for the workbook (`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`). Sniff magic bytes; don't trust the client.
- **Storage:**
  ```
  /var/lib/ite-calibration/data/
    runs/<run_id>/
      references/<file_id>__<sanitized_original>.csv
      calibration/<file_id>__<sanitized_original>.xlsx
      certificates/<result_id>__<cert_no>.docx
  ```
  Filenames sanitized; UUID path segments prevent traversal.
- **Integrity:** sha256 computed on upload, stored, verified on download.
- **Downloads:** served by FastAPI (not nginx static) so auth + access logging apply. `Content-Disposition: attachment`.

### Transport & deployment hardening

- TLS at nginx (self-signed for LAN with documented CA install, or internal Let's Encrypt).
- Headers: HSTS, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, CSP `default-src 'self'; img-src 'self' data:; font-src 'self' https://fonts.gstatic.com; style-src 'self' https://fonts.googleapis.com; script-src 'self'`.
- Postgres reachable only via Docker internal network.
- Backups: nightly `pg_dump` + `tar` of `/data` to a separate volume; documented restore.

### Logging & audit

- Structured JSON logs to stdout.
- `audit_log` captures: login, login_failed, run.created, run.processed, run.deleted, user.created, user.role_changed, cert.downloaded.
- Run Detail "Audit trail" tab reads from `audit_log` filtered to that run.

---

## 6. v1 build order, testing & error handling

### Build order (vertical slices)

**Slice 0 — Skeleton (~0.5d).** Monorepo scaffold; `docker compose up` brings up Postgres + empty FastAPI (`/api/health`) + nginx serving an empty Vite shell; Alembic initialized; CI runs lint + tests.

**Slice 1 — Auth + AppShell (~1d).** `users`, `sessions`, `password_resets` tables. `POST /auth/login`, `POST /auth/logout`, `GET /auth/me`, refresh middleware. `python -m ite_api.cli create-admin --email ...` bootstraps the first user. Frontend `LoginPage`, `AuthProvider`, `<RequireAuth>`, `AppShell` (sidebar + topbar matching the design; deferred pages as "Coming soon" stubs).

**Slice 2 — Calibration engine (no UI) (~2d).** Build `apps/api/ite_api/calibration/` fresh: `ref_loader.py`, `cal_loader.py`, `matcher.py` (3-step algorithm), `docx_filler.py`. Unit tests against fixture CSVs/XLSX copied from `Old Method/`. CLI command `python -m ite_api.cli run-calibration <fixtures-dir>` → writes `.docx`. Done when output matches a known-good Old Method certificate.

**Slice 3 — New Calibration end-to-end (~2d).** `calibration_runs`, `run_reference_files`, `run_calibration_file`, `logger_results`, `loggers`, `audit_log` tables. `POST /runs`, upload routes, `POST /runs/{id}/process` (BackgroundTask), `GET /runs/{id}/status`, certificate download. Frontend `NewCalibrationPage`.

**Slice 4 — History + Run Detail (~1.5d).** `GET /runs`, `GET /runs/{id}`. Frontend `HistoryPage` (table ↔ cards), `RunDetailPage` (4 tabs), zip download.

**Slice 5 — Overview (~1d).** `GET /overview`. Frontend `OverviewPage` with 4 stat tiles (no sparklines), recent + due-soon rails.

**Slice 6 — Polish & handoff (~1d).** Admin user-mgmt UI (list, invite, change role, disable). Backups script + restore doc. README setup + ops runbook.

Total ≈ **9 working days** for v1 by one developer.

### Testing

- **API (pytest):**
  - Unit: calibration engine modules with fixture files (golden outputs).
  - Integration: full FastAPI app with a real Postgres (`testcontainers`); **never mock the DB**.
  - Auth: dedicated tests for login, refresh rotation, lockout, role enforcement on every mutating route.
- **Web:** Vitest + React Testing Library for components/hooks. Playwright for one e2e happy-path: login → create run → upload → process → download.
- **CI:** GitHub Actions, separate api and web jobs, both must pass to merge.

### Error handling

- **API errors:** RFC 7807 `application/problem+json` with `errors[]` field paths for validation.
- **Engine errors:** run status → `failed`, `failure_reason` JSONB populated, `audit_log` records detail, frontend shows message verbatim with "Re-upload" CTA. No swallowing into generic messages.
- **Frontend:**
  - 401 → silent refresh attempt → /login on failure.
  - 403 → inline "no permission" message, no redirect.
  - 5xx → toast + retry; log with `X-Request-ID`.
  - Form validation: Zod client + Pydantic server, same field-path shape.

### Observability

- Structured JSON logs to stdout, captured by Docker.
- `X-Request-ID` (uuid4) per request, in logs and error responses.
- No external observability stack in v1.

### Out of scope for v1

- Logger profile + drift chart
- Upcoming/due page (the `loggers.next_due_at` column exists but isn't surfaced yet)
- Settings (Reference standards, Defaults, Template, Integrations panels)
- Certificate preview/PDF viewer in-browser (download .docx works; PDF conversion deferred)
- SSO, MFA
- Email sending (password setup links shown to admin manually)
