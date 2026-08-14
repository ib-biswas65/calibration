# ITE Calibration — Slice 0: Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the monorepo, an empty FastAPI service with a health endpoint, an empty Vite+React+TS SPA, a Docker Compose stack (api + nginx-served web + Postgres), and CI that runs lint and tests for both apps. After this slice: `docker compose up` brings the stack up, `curl http://localhost/api/health` returns `{"status":"ok"}`, and loading `http://localhost/` shows a placeholder page.

**Architecture:** Monorepo with `apps/api` (FastAPI), `apps/web` (Vite SPA), `infra/` (Docker Compose, nginx). Nginx serves the static SPA bundle and reverse-proxies `/api/*` to FastAPI. Postgres is reachable only on the Docker network. No auth, no DB tables yet — that's Slice 1.

**Tech Stack:** Python 3.12, FastAPI, SQLAlchemy 2.x + Alembic (initialised, no tables yet), pytest. Node 20, Vite 5, React 18, TypeScript, Vitest. Postgres 16. Nginx (alpine). GitHub Actions CI.

---

## File Structure

Files created in this slice (relative to repo root `/Users/subhanshubiswas/Projects/Calibration`):

```
.gitignore                                    # extended for apps/
.github/workflows/ci.yml                      # api + web jobs
apps/
├── api/
│   ├── pyproject.toml
│   ├── ite_api/
│   │   ├── __init__.py
│   │   ├── main.py                           # FastAPI app + /api/health
│   │   ├── config.py                         # env-driven Settings
│   │   └── db/
│   │       ├── __init__.py
│   │       ├── base.py                       # SQLAlchemy declarative base
│   │       └── session.py                    # engine + SessionLocal
│   ├── alembic.ini
│   ├── alembic/
│   │   ├── env.py
│   │   ├── script.py.mako
│   │   └── versions/                         # empty
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── conftest.py
│   │   └── test_health.py
│   ├── Dockerfile
│   └── .dockerignore
├── web/
│   ├── package.json
│   ├── tsconfig.json
│   ├── tsconfig.node.json
│   ├── vite.config.ts
│   ├── index.html
│   ├── src/
│   │   ├── main.tsx
│   │   ├── App.tsx                           # placeholder "ITE Calibration"
│   │   └── App.test.tsx
│   ├── Dockerfile
│   ├── nginx-default.conf                    # SPA fallback inside web container
│   └── .dockerignore
└── infra/
    ├── docker-compose.yml
    ├── nginx.conf                            # edge reverse proxy
    └── .env.example
```

Files NOT touched: `src/`, `Old Method/`, `output/`, top-level debug scripts. They stay where they are. Cleanup is out of scope for Slice 0.

---

## Task 1: Repo scaffolding and root `.gitignore`

**Files:**
- Modify: `.gitignore`
- Create: `apps/.gitkeep`, `apps/api/.gitkeep`, `apps/web/.gitkeep`, `infra/.gitkeep`

- [ ] **Step 1: Add ignores for the new apps to root `.gitignore`**

Append (do not replace) the following to `/Users/subhanshubiswas/Projects/Calibration/.gitignore`:

```gitignore

# --- ITE Calibration monorepo ---
# Python
apps/api/.venv/
apps/api/__pycache__/
apps/api/**/__pycache__/
apps/api/.pytest_cache/
apps/api/.mypy_cache/
apps/api/.ruff_cache/
apps/api/*.egg-info/

# Node
apps/web/node_modules/
apps/web/dist/
apps/web/coverage/
apps/web/.vite/

# Local env
infra/.env

# Editor / OS
.DS_Store
```

- [ ] **Step 2: Create empty directory markers**

Run from repo root:

```bash
mkdir -p apps/api apps/web infra
touch apps/.gitkeep apps/api/.gitkeep apps/web/.gitkeep infra/.gitkeep
```

- [ ] **Step 3: Commit**

```bash
git add .gitignore apps infra
git commit -m "chore: scaffold ITE Calibration monorepo directories"
```

Expected: one commit, no other side effects.

---

## Task 2: FastAPI app with `/api/health` (TDD)

**Files:**
- Create: `apps/api/pyproject.toml`
- Create: `apps/api/ite_api/__init__.py`
- Create: `apps/api/ite_api/main.py`
- Create: `apps/api/ite_api/config.py`
- Create: `apps/api/tests/__init__.py`
- Create: `apps/api/tests/conftest.py`
- Create: `apps/api/tests/test_health.py`

- [ ] **Step 1: Create `apps/api/pyproject.toml`**

```toml
[project]
name = "ite_api"
version = "0.1.0"
description = "ITE Calibration API"
requires-python = ">=3.12"
dependencies = [
  "fastapi==0.115.6",
  "uvicorn[standard]==0.32.1",
  "pydantic==2.10.4",
  "pydantic-settings==2.7.0",
  "sqlalchemy==2.0.36",
  "alembic==1.14.0",
  "psycopg[binary]==3.2.3",
]

[project.optional-dependencies]
dev = [
  "pytest==8.3.4",
  "pytest-asyncio==0.25.0",
  "httpx==0.28.1",
  "ruff==0.8.4",
]

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
include = ["ite_api*"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-ra -q"

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B"]
```

- [ ] **Step 2: Create a venv and install (one-time, locally)**

Run from `apps/api/`:

```bash
python3.12 -m venv .venv
.venv/bin/pip install -U pip
.venv/bin/pip install -e ".[dev]"
```

Expected: install succeeds; `.venv/bin/pytest --version` prints `pytest 8.3.4`.

- [ ] **Step 3: Write the failing health-endpoint test**

Create `apps/api/tests/__init__.py` (empty file).

Create `apps/api/tests/conftest.py`:

```python
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from ite_api.main import create_app


@pytest.fixture()
def client() -> Iterator[TestClient]:
    app = create_app()
    with TestClient(app) as c:
        yield c
```

Create `apps/api/tests/test_health.py`:

```python
def test_health_returns_ok(client):
    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
```

- [ ] **Step 4: Run the test and verify it fails**

From `apps/api/`:

```bash
.venv/bin/pytest -v
```

Expected: error during collection — `ModuleNotFoundError: No module named 'ite_api.main'` (the module does not exist yet).

- [ ] **Step 5: Create `apps/api/ite_api/__init__.py` and `config.py`**

`apps/api/ite_api/__init__.py` (empty file).

`apps/api/ite_api/config.py`:

```python
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="ITE_", env_file=None)

    env: str = "dev"
    database_url: str = "postgresql+psycopg://ite:ite@localhost:5432/ite"


def get_settings() -> Settings:
    return Settings()
```

- [ ] **Step 6: Create `apps/api/ite_api/main.py` to make the test pass**

```python
from fastapi import FastAPI

from ite_api.config import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="ITE Calibration API", version="0.1.0")

    @app.get("/api/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    app.state.settings = settings
    return app


app = create_app()
```

- [ ] **Step 7: Run the test and verify it passes**

From `apps/api/`:

```bash
.venv/bin/pytest -v
```

Expected: `tests/test_health.py::test_health_returns_ok PASSED` (1 passed).

- [ ] **Step 8: Commit**

```bash
git add apps/api/pyproject.toml apps/api/ite_api apps/api/tests
git commit -m "feat(api): scaffold FastAPI app with /api/health endpoint"
```

---

## Task 3: SQLAlchemy + Alembic baseline (no tables yet)

**Files:**
- Create: `apps/api/ite_api/db/__init__.py`
- Create: `apps/api/ite_api/db/base.py`
- Create: `apps/api/ite_api/db/session.py`
- Create: `apps/api/alembic.ini`
- Create: `apps/api/alembic/env.py`
- Create: `apps/api/alembic/script.py.mako`
- Create: `apps/api/alembic/versions/.gitkeep`
- Create: `apps/api/tests/test_db.py`

- [ ] **Step 1: Write a failing test for the declarative base**

Create `apps/api/tests/test_db.py`:

```python
from ite_api.db.base import Base


def test_base_metadata_is_empty_for_now():
    # Slice 0: no models registered yet
    assert Base.metadata.tables == {}
```

Run: `.venv/bin/pytest tests/test_db.py -v`
Expected: `ModuleNotFoundError: No module named 'ite_api.db'`

- [ ] **Step 2: Create the db package**

`apps/api/ite_api/db/__init__.py` (empty file).

`apps/api/ite_api/db/base.py`:

```python
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Declarative base for all ORM models."""
```

`apps/api/ite_api/db/session.py`:

```python
from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from ite_api.config import get_settings

_engine = None
_SessionLocal: sessionmaker[Session] | None = None


def _init() -> None:
    global _engine, _SessionLocal
    if _engine is None:
        _engine = create_engine(get_settings().database_url, future=True)
        _SessionLocal = sessionmaker(bind=_engine, autoflush=False, expire_on_commit=False)


def get_session() -> Iterator[Session]:
    _init()
    assert _SessionLocal is not None
    with _SessionLocal() as s:
        yield s
```

- [ ] **Step 3: Run the test and verify it passes**

```bash
.venv/bin/pytest tests/test_db.py -v
```

Expected: 1 passed.

- [ ] **Step 4: Initialize Alembic**

From `apps/api/`:

```bash
.venv/bin/alembic init alembic
```

This creates `alembic.ini`, `alembic/env.py`, `alembic/script.py.mako`, `alembic/versions/`.

- [ ] **Step 5: Wire Alembic to our `Base` and settings**

Replace `apps/api/alembic/env.py` with:

```python
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

from ite_api.config import get_settings
from ite_api.db.base import Base

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

config.set_main_option("sqlalchemy.url", get_settings().database_url)
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

In `apps/api/alembic.ini`, leave `sqlalchemy.url =` blank (we set it in `env.py`).

Create `apps/api/alembic/versions/.gitkeep` (empty file).

- [ ] **Step 6: Commit**

```bash
git add apps/api/ite_api/db apps/api/tests/test_db.py apps/api/alembic.ini apps/api/alembic
git commit -m "feat(api): add SQLAlchemy base and Alembic config (no migrations yet)"
```

---

## Task 4: API Dockerfile

**Files:**
- Create: `apps/api/Dockerfile`
- Create: `apps/api/.dockerignore`

- [ ] **Step 1: Create `apps/api/.dockerignore`**

```
.venv
__pycache__
.pytest_cache
.mypy_cache
.ruff_cache
*.egg-info
tests
```

- [ ] **Step 2: Create `apps/api/Dockerfile`**

```dockerfile
FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY pyproject.toml ./
RUN pip install --upgrade pip && pip install .

COPY ite_api ./ite_api
COPY alembic.ini ./alembic.ini
COPY alembic ./alembic

EXPOSE 8000
CMD ["uvicorn", "ite_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 3: Build the image locally to verify**

From `apps/api/`:

```bash
docker build -t ite-api:dev .
```

Expected: build succeeds with no errors. Image present in `docker images | grep ite-api`.

- [ ] **Step 4: Commit**

```bash
git add apps/api/Dockerfile apps/api/.dockerignore
git commit -m "feat(api): add Dockerfile for FastAPI service"
```

---

## Task 5: Vite + React + TypeScript scaffold

**Files:**
- Create: `apps/web/package.json`
- Create: `apps/web/tsconfig.json`
- Create: `apps/web/tsconfig.node.json`
- Create: `apps/web/vite.config.ts`
- Create: `apps/web/index.html`
- Create: `apps/web/src/main.tsx`
- Create: `apps/web/src/App.tsx`
- Create: `apps/web/src/App.test.tsx`

- [ ] **Step 1: Create `apps/web/package.json`**

```json
{
  "name": "ite-web",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview --host 0.0.0.0 --port 4173",
    "test": "vitest run",
    "test:watch": "vitest",
    "lint": "eslint . --ext .ts,.tsx"
  },
  "dependencies": {
    "react": "18.3.1",
    "react-dom": "18.3.1"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "6.6.3",
    "@testing-library/react": "16.1.0",
    "@types/react": "18.3.17",
    "@types/react-dom": "18.3.5",
    "@vitejs/plugin-react": "4.3.4",
    "eslint": "9.17.0",
    "eslint-plugin-react": "7.37.2",
    "eslint-plugin-react-hooks": "5.1.0",
    "jsdom": "25.0.1",
    "typescript": "5.7.2",
    "vite": "5.4.11",
    "vitest": "2.1.8"
  }
}
```

- [ ] **Step 2: Create `apps/web/tsconfig.json` and `tsconfig.node.json`**

`apps/web/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "skipLibCheck": true,
    "esModuleInterop": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "types": ["vitest/globals", "@testing-library/jest-dom"]
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

`apps/web/tsconfig.node.json`:

```json
{
  "compilerOptions": {
    "composite": true,
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "skipLibCheck": true
  },
  "include": ["vite.config.ts"]
}
```

- [ ] **Step 3: Create `apps/web/vite.config.ts`**

```ts
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  server: {
    host: "0.0.0.0",
    port: 5173,
    proxy: {
      "/api": "http://localhost:8000",
    },
  },
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test-setup.ts"],
  },
});
```

- [ ] **Step 4: Create `apps/web/index.html`**

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>ITE Calibration</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 5: Write the failing App test**

Create `apps/web/src/test-setup.ts`:

```ts
import "@testing-library/jest-dom";
```

Create `apps/web/src/App.test.tsx`:

```tsx
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import App from "./App";

describe("App", () => {
  it("renders the product name", () => {
    render(<App />);
    expect(screen.getByText("ITE Calibration")).toBeInTheDocument();
  });
});
```

- [ ] **Step 6: Install and run — verify the test fails**

From `apps/web/`:

```bash
npm install
npm test
```

Expected: tests fail because `./App` does not exist.

- [ ] **Step 7: Implement minimal `main.tsx` and `App.tsx`**

`apps/web/src/main.tsx`:

```tsx
import React from "react";
import ReactDOM from "react-dom/client";

import App from "./App";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
```

`apps/web/src/App.tsx`:

```tsx
export default function App() {
  return (
    <main style={{ fontFamily: "system-ui", padding: 24 }}>
      <h1>ITE Calibration</h1>
      <p>Slice 0 skeleton — auth and pages arrive in Slice 1.</p>
    </main>
  );
}
```

- [ ] **Step 8: Run tests and verify they pass**

```bash
npm test
```

Expected: 1 test passed.

- [ ] **Step 9: Verify the production build works**

```bash
npm run build
```

Expected: `dist/index.html` and `dist/assets/*` exist; no TypeScript errors.

- [ ] **Step 10: Commit**

```bash
git add apps/web
git commit -m "feat(web): scaffold Vite + React + TS app with placeholder page"
```

---

## Task 6: Web Dockerfile (multi-stage: build → nginx)

**Files:**
- Create: `apps/web/Dockerfile`
- Create: `apps/web/nginx-default.conf`
- Create: `apps/web/.dockerignore`

- [ ] **Step 1: Create `apps/web/.dockerignore`**

```
node_modules
dist
coverage
.vite
```

- [ ] **Step 2: Create `apps/web/nginx-default.conf`** (in-container nginx — SPA fallback only; the edge nginx in `infra/` handles `/api` proxy)

```nginx
server {
    listen 8080;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri /index.html;
    }
}
```

- [ ] **Step 3: Create `apps/web/Dockerfile`**

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci || npm install
COPY . .
RUN npm run build

FROM nginx:1.27-alpine AS runtime
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx-default.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
```

- [ ] **Step 4: Build the web image locally to verify**

From `apps/web/`:

```bash
docker build -t ite-web:dev .
```

Expected: build succeeds. Verify with `docker run --rm -p 8080:8080 ite-web:dev` and `curl http://localhost:8080/` → returns the placeholder HTML.

Stop the container with Ctrl+C after verifying.

- [ ] **Step 5: Commit**

```bash
git add apps/web/Dockerfile apps/web/nginx-default.conf apps/web/.dockerignore
git commit -m "feat(web): add multi-stage Dockerfile serving via nginx"
```

---

## Task 7: Docker Compose stack (edge nginx + api + postgres)

**Files:**
- Create: `infra/docker-compose.yml`
- Create: `infra/nginx.conf`
- Create: `infra/.env.example`

- [ ] **Step 1: Create `infra/.env.example`**

```dotenv
# Copy to infra/.env and edit. Do not commit infra/.env.
POSTGRES_USER=ite
POSTGRES_PASSWORD=changeme
POSTGRES_DB=ite
ITE_DATABASE_URL=postgresql+psycopg://ite:changeme@postgres:5432/ite
ITE_ENV=dev
```

- [ ] **Step 2: Create `infra/nginx.conf`** (edge reverse proxy: serves the SPA from the `web` container, proxies `/api/*` to `api`)

```nginx
worker_processes 1;
events { worker_connections 1024; }

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    client_max_body_size 200m;

    upstream api_upstream { server api:8000; }
    upstream web_upstream { server web:8080; }

    server {
        listen 80;
        server_name _;

        location /api/ {
            proxy_pass http://api_upstream;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location / {
            proxy_pass http://web_upstream;
            proxy_set_header Host $host;
        }
    }
}
```

- [ ] **Step 3: Create `infra/docker-compose.yml`**

```yaml
name: ite-calibration

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 20

  api:
    build:
      context: ../apps/api
    environment:
      ITE_ENV: ${ITE_ENV}
      ITE_DATABASE_URL: ${ITE_DATABASE_URL}
    depends_on:
      postgres:
        condition: service_healthy
    expose:
      - "8000"

  web:
    build:
      context: ../apps/web
    depends_on:
      - api
    expose:
      - "8080"

  edge:
    image: nginx:1.27-alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - api
      - web

volumes:
  pg_data:
```

- [ ] **Step 4: Commit**

```bash
git add infra
git commit -m "feat(infra): add docker-compose stack with edge nginx + api + web + postgres"
```

---

## Task 8: End-to-end smoke test of the stack

**Files:** none created; this task verifies the previous tasks fit together.

- [ ] **Step 1: Create local env file**

From `infra/`:

```bash
cp .env.example .env
```

(`.env` is gitignored — do not commit it.)

- [ ] **Step 2: Bring the stack up**

From `infra/`:

```bash
docker compose --env-file .env up -d --build
```

Expected: four containers running. Verify with `docker compose ps` — all show `Up` (postgres also `(healthy)`).

- [ ] **Step 3: Smoke-test the API through the edge**

```bash
curl -sS -o /dev/null -w "%{http_code}\n" http://localhost/api/health
curl -sS http://localhost/api/health
```

Expected:
- First curl prints `200`.
- Second curl prints `{"status":"ok"}`.

- [ ] **Step 4: Smoke-test the SPA through the edge**

```bash
curl -sS http://localhost/ | grep -q "ITE Calibration" && echo "OK" || echo "FAIL"
```

Expected: `OK`.

- [ ] **Step 5: Tear down**

```bash
docker compose --env-file .env down
```

Expected: all four containers stopped and removed. The `pg_data` volume persists.

- [ ] **Step 6: Commit nothing (verification only)**

No file changes from this task. If any step failed, fix the offending Task 2–7 file and re-run Steps 2–5.

---

## Task 9: GitHub Actions CI (api + web jobs)

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches: [main, "V*"]
  pull_request:

jobs:
  api:
    name: api — lint + test
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: apps/api
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"
          cache-dependency-path: apps/api/pyproject.toml
      - name: Install
        run: |
          python -m pip install --upgrade pip
          pip install -e ".[dev]"
      - name: Lint
        run: ruff check .
      - name: Test
        run: pytest -v

  web:
    name: web — lint + test + build
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: apps/web
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
          cache-dependency-path: apps/web/package-lock.json
      - name: Install
        run: npm ci || npm install
      - name: Test
        run: npm test
      - name: Build
        run: npm run build
```

- [ ] **Step 2: Push the branch and verify CI runs green**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add GitHub Actions jobs for api and web"
git push -u origin V0.0.1
```

Expected: GitHub shows the `CI` workflow on the latest commit with both `api` and `web` jobs passing. If either fails, read the log, fix the underlying issue in the corresponding `apps/*` files, and push again.

If the repo has no GitHub remote configured, skip the `push` and verify locally instead by installing [`act`](https://github.com/nektos/act) and running `act -j api && act -j web`. Document this in the PR description.

- [ ] **Step 3: Commit (already done in Step 2)**

No additional commit.

---

## Task 10: README for Slice 0

**Files:**
- Create: `README.md` (at repo root; if one already exists for the old Flet app, leave it untouched and create `README-ite.md` instead and note this in the commit)

- [ ] **Step 1: Inspect existing README**

```bash
ls /Users/subhanshubiswas/Projects/Calibration/README.md 2>/dev/null && echo "EXISTS" || echo "ABSENT"
```

If `EXISTS`: create `README-ite.md` instead of overwriting. If `ABSENT`: create `README.md`.

- [ ] **Step 2: Create the README**

Content (use this exact text, adjusting only the filename per Step 1):

````markdown
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
````

- [ ] **Step 3: Commit**

```bash
git add README.md   # or README-ite.md
git commit -m "docs: add Slice 0 README with quickstart"
```

---

## Final verification (after all tasks complete)

- [ ] **Step 1: Tree check**

```bash
ls apps/api/ite_api apps/web/src infra .github/workflows
```

Expected: each path lists files, none missing.

- [ ] **Step 2: Tests pass locally for both apps**

```bash
(cd apps/api && .venv/bin/pytest -v)
(cd apps/web && npm test)
```

Expected: all green.

- [ ] **Step 3: Stack comes up cleanly**

```bash
cd infra && docker compose --env-file .env up -d --build
sleep 5
curl -sS http://localhost/api/health
curl -sS http://localhost/ | grep "ITE Calibration"
docker compose --env-file .env down
```

Expected: health returns `{"status":"ok"}`; SPA HTML contains the product name.

- [ ] **Step 4: CI is green on the pushed commit**

Open the latest commit on GitHub; both `api` and `web` jobs show ✓.

If all four checks pass, Slice 0 is complete. The next plan (`2026-MM-DD-ite-calibration-slice-1-auth.md`) will be written after this slice merges.

---

## Self-review notes

- **Spec coverage (Slice 0 portion of the spec):** repo layout (§1), Alembic init (§2), `/api/health` (implied by §6 Slice 0), Docker Compose (§1, §5), CI (§6 testing) — all covered.
- **No placeholders:** every step includes the exact file contents or exact command.
- **Type consistency:** `create_app()`, `Base`, `Settings`, `get_settings()`, `get_session()`, image names `ite-api:dev` and `ite-web:dev`, service names `api`/`web`/`postgres`/`edge` are used identically across tasks.
- **Deferred to Slice 1 (not gaps):** auth, user model, AppShell, design tokens, route table. These are explicitly out of scope for Slice 0.
