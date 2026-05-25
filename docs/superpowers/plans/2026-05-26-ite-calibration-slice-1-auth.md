# ITE Calibration — Slice 1: Auth + AppShell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up email+password authentication (argon2 + JWT access cookie + opaque refresh cookie with rotation), the React AppShell (sidebar + topbar matching the design with "Coming soon" stubs for deferred pages), and the LoginPage. After this slice: an admin created via CLI can log in, land on an empty Overview page, and log out.

**Architecture:** Two-token cookie auth — short-lived (15 min) JWT access in `ite_at`, opaque 256-bit refresh in `ite_rt` (server stores only `sha256(token)`). Refresh middleware silently rotates on expired access. Roles `admin` / `engineer` / `viewer` enforced server-side. Frontend uses TanStack Query + React Hook Form + Zod. Plain CSS modules with CSS-variable design tokens. Tests run against a real Postgres via `testcontainers`.

**Tech Stack:** Adds to Slice 0 — `argon2-cffi`, `pyjwt`, `testcontainers[postgres]`. Frontend adds `react-router-dom`, `@tanstack/react-query`, `react-hook-form`, `zod`, `lucide-react`, `@playwright/test`.

**Spec scope-tightening:** Pulling `audit_log` into this slice's migration (spec §6 lists it in Slice 3, but login telemetry needs it from day one — cheaper to ship now than retrofit). Admin user-management routes (`POST /auth/users`, `PATCH /auth/users/{id}`) are deferred to Slice 6 per spec.

---

## File Structure

Files created or modified in this slice (relative to repo root):

```
apps/api/
├── pyproject.toml                                  # add auth + test deps, JWT secret
├── ite_api/
│   ├── config.py                                   # add jwt_secret, cookie names, durations
│   ├── main.py                                     # wire router, refresh middleware, origin middleware
│   ├── auth/
│   │   ├── __init__.py
│   │   ├── passwords.py                            # argon2 hash + verify
│   │   ├── tokens.py                               # JWT encode/decode, opaque refresh token, hashing
│   │   ├── dependencies.py                         # current_user, require_role
│   │   └── lockout.py                              # failed-login tracking + cooldown
│   ├── db/
│   │   └── models/
│   │       ├── __init__.py                         # re-exports
│   │       ├── user.py
│   │       ├── session.py
│   │       ├── password_reset.py
│   │       └── audit_log.py
│   ├── middleware/
│   │   ├── __init__.py
│   │   └── origin.py                               # Origin header check on mutating routes
│   ├── routes/
│   │   ├── __init__.py
│   │   └── auth.py                                 # POST /login, POST /logout, GET /me
│   ├── cli.py                                      # create-admin command
│   └── audit.py                                    # write_audit_log helper
├── alembic/versions/
│   └── 0001_users_sessions_passwordresets_audit.py # first migration
└── tests/
    ├── conftest.py                                 # add postgres-container fixture, db_session
    ├── auth/
    │   ├── __init__.py
    │   ├── test_passwords.py
    │   ├── test_tokens.py
    │   ├── test_lockout.py
    │   └── test_dependencies.py
    ├── routes/
    │   ├── __init__.py
    │   └── test_auth.py                             # login, refresh, logout, me
    ├── middleware/
    │   ├── __init__.py
    │   └── test_origin.py
    └── test_cli.py

apps/web/
├── package.json                                    # add router, query, RHF, zod, lucide, playwright
├── playwright.config.ts                            # new
├── src/
│   ├── main.tsx                                    # wrap App with QueryClientProvider + Router + AuthProvider
│   ├── App.tsx                                     # route table
│   ├── theme/
│   │   ├── tokens.css                              # all design tokens (green-dominant)
│   │   └── reset.css
│   ├── api/
│   │   ├── client.ts                               # typed fetch wrapper, 401 silent-refresh, JSON
│   │   └── types.ts                                # User, AuthMe shapes
│   ├── auth/
│   │   ├── AuthProvider.tsx
│   │   ├── useAuth.ts
│   │   └── RequireAuth.tsx
│   ├── components/
│   │   ├── AppShell.tsx
│   │   ├── Sidebar.tsx
│   │   ├── Topbar.tsx
│   │   └── ComingSoon.tsx                          # stub for deferred pages
│   └── pages/
│       ├── LoginPage.tsx
│       ├── OverviewPage.tsx                        # empty placeholder for Slice 1
│       ├── NewCalibrationPage.tsx                  # "Coming soon"
│       ├── HistoryPage.tsx                         # "Coming soon"
│       ├── RunDetailPage.tsx                       # "Coming soon"
│       ├── UpcomingPage.tsx                        # "Coming soon"
│       ├── LoggerProfilePage.tsx                   # "Coming soon"
│       ├── CertificatePage.tsx                     # "Coming soon"
│       └── SettingsPage.tsx                        # "Coming soon"
└── e2e/
    └── auth.spec.ts                                # Playwright: login → overview → logout

infra/
├── .env.example                                    # add JWT secret
└── docker-compose.yml                              # add ITE_JWT_SECRET to api

.github/workflows/
└── ci.yml                                          # add postgres service + ITE_JWT_SECRET to api job
```

---

## Task 1: Add auth dependencies, JWT secret, cookie/duration settings

**Files:**
- Modify: `apps/api/pyproject.toml`
- Modify: `apps/api/ite_api/config.py`
- Modify: `infra/.env.example`
- Modify: `infra/docker-compose.yml`
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Add new dependencies to `apps/api/pyproject.toml`**

Replace the `dependencies` and `dev` arrays with:

```toml
dependencies = [
  "fastapi==0.115.6",
  "uvicorn[standard]==0.32.1",
  "pydantic==2.10.4",
  "pydantic-settings==2.7.0",
  "sqlalchemy==2.0.36",
  "alembic==1.14.0",
  "psycopg[binary]==3.2.3",
  "argon2-cffi==23.1.0",
  "pyjwt==2.10.1",
  "typer==0.15.1",
]

[project.optional-dependencies]
dev = [
  "pytest==8.3.4",
  "pytest-asyncio==0.25.0",
  "httpx==0.28.1",
  "ruff==0.8.4",
  "testcontainers[postgres]==4.9.0",
]
```

- [ ] **Step 2: Install new deps**

From `apps/api/`:

```bash
.venv/bin/pip install -e ".[dev]" --quiet
```

Expected: install succeeds. `argon2`, `jwt`, `typer`, `testcontainers` all importable.

- [ ] **Step 3: Extend `apps/api/ite_api/config.py`**

```python
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="ITE_", env_file=None)

    env: str = "dev"
    database_url: str = "postgresql+psycopg://ite:ite@localhost:5432/ite"

    jwt_secret: str = "dev-only-change-me"
    access_token_minutes: int = 15
    refresh_token_days: int = 14
    cookie_access_name: str = "ite_at"
    cookie_refresh_name: str = "ite_rt"
    cookie_secure: bool = False  # set true in prod
    cookie_samesite: str = "lax"

    lockout_max_attempts: int = 10
    lockout_window_minutes: int = 15
    lockout_cooldown_minutes: int = 15


def get_settings() -> Settings:
    return Settings()
```

- [ ] **Step 4: Add JWT secret to `infra/.env.example`**

Append:

```dotenv
ITE_JWT_SECRET=dev-only-change-me-32-chars-min-please
```

- [ ] **Step 5: Wire env into `infra/docker-compose.yml` api service**

In the `api:` block under `environment:`, add the line:

```yaml
      ITE_JWT_SECRET: ${ITE_JWT_SECRET}
```

- [ ] **Step 6: Add JWT secret to the CI workflow `apps/api` job**

In `.github/workflows/ci.yml`, in the `api:` job under the `Test` step, change to:

```yaml
      - name: Test
        env:
          ITE_JWT_SECRET: ci-test-secret-not-real
        run: pytest -v
```

- [ ] **Step 7: Verify existing tests still pass**

From `apps/api/`:

```bash
ITE_JWT_SECRET=test-secret .venv/bin/pytest -v
```

Expected: 2 passed.

- [ ] **Step 8: Commit**

```bash
git add apps/api/pyproject.toml apps/api/ite_api/config.py infra/.env.example infra/docker-compose.yml .github/workflows/ci.yml
git commit -m "feat(api): add auth deps and JWT/cookie/lockout settings"
```

---

## Task 2: Postgres container fixture for integration tests

**Files:**
- Modify: `apps/api/tests/conftest.py`

- [ ] **Step 1: Replace `apps/api/tests/conftest.py`**

```python
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session, sessionmaker
from testcontainers.postgres import PostgresContainer

from ite_api.db.base import Base


@pytest.fixture(scope="session")
def postgres_url() -> Iterator[str]:
    with PostgresContainer("postgres:16-alpine", driver="psycopg") as pg:
        url = pg.get_connection_url()
        yield url


@pytest.fixture(scope="session")
def engine(postgres_url: str):
    import ite_api.db.models  # noqa: F401  ensure models register on Base.metadata

    eng = create_engine(postgres_url, future=True)
    Base.metadata.create_all(eng)
    yield eng
    eng.dispose()


@pytest.fixture()
def db_session(engine) -> Iterator[Session]:
    SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    with SessionLocal() as s:
        yield s
        s.rollback()
    # truncate everything to keep tests isolated
    with engine.begin() as conn:
        tables = ",".join(f'"{t}"' for t in reversed(Base.metadata.sorted_tables) for t in [t.name])
        if tables:
            conn.execute(text(f"TRUNCATE {tables} RESTART IDENTITY CASCADE"))


@pytest.fixture()
def client(postgres_url: str, monkeypatch) -> Iterator[TestClient]:
    monkeypatch.setenv("ITE_DATABASE_URL", postgres_url)
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    from ite_api.main import create_app  # late import so env is in place
    app = create_app()
    with TestClient(app) as c:
        yield c
```

- [ ] **Step 2: Add an empty `apps/api/ite_api/db/models/__init__.py` placeholder**

```python
# Re-exports all ORM models so Base.metadata sees them. Filled in Task 3.
```

- [ ] **Step 3: Run existing tests to verify the fixture loads**

```bash
.venv/bin/pytest -v 2>&1 | tail -10
```

Expected: 2 tests pass (a Postgres container is spun up briefly even though the existing tests don't use `db_session` — that's fine).

- [ ] **Step 4: Commit**

```bash
git add apps/api/tests/conftest.py apps/api/ite_api/db/models/__init__.py
git commit -m "test(api): add testcontainers postgres fixture and db_session"
```

---

## Task 3: User, Session, PasswordReset, AuditLog models + first Alembic migration

**Files:**
- Create: `apps/api/ite_api/db/models/user.py`
- Create: `apps/api/ite_api/db/models/session.py`
- Create: `apps/api/ite_api/db/models/password_reset.py`
- Create: `apps/api/ite_api/db/models/audit_log.py`
- Modify: `apps/api/ite_api/db/models/__init__.py`
- Create: `apps/api/alembic/versions/0001_initial_auth_schema.py`
- Create: `apps/api/tests/test_models.py`

- [ ] **Step 1: Write failing model-import test**

`apps/api/tests/test_models.py`:

```python
from ite_api.db.models import AuditLog, PasswordReset, Session as UserSession, User


def test_models_register_on_metadata():
    from ite_api.db.base import Base
    names = set(Base.metadata.tables.keys())
    assert {"users", "sessions", "password_resets", "audit_log"} <= names


def test_user_role_default(db_session):
    u = User(email="a@b.co", password_hash="x", full_name="A", role="admin")
    db_session.add(u)
    db_session.flush()
    assert u.id is not None
    assert u.disabled is False
```

Run: `.venv/bin/pytest tests/test_models.py -v`
Expected: collection error — `cannot import name 'AuditLog'`.

- [ ] **Step 2: Create `apps/api/ite_api/db/models/user.py`**

```python
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from ite_api.db.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(320), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(200), nullable=False)
    role: Mapped[str] = mapped_column(String(20), nullable=False)
    disabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
```

Note: spec calls for `citext` for email. We use a unique `String` with a `lower(email)` enforced at the auth layer (simpler, no extension dependency in test container).

- [ ] **Step 3: Create `apps/api/ite_api/db/models/session.py`**

```python
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from ite_api.db.base import Base


class Session(Base):
    __tablename__ = "sessions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
```

- [ ] **Step 4: Create `apps/api/ite_api/db/models/password_reset.py`**

```python
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from ite_api.db.base import Base


class PasswordReset(Base):
    __tablename__ = "password_resets"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
```

- [ ] **Step 5: Create `apps/api/ite_api/db/models/audit_log.py`**

```python
import uuid
from datetime import datetime

from sqlalchemy import BigInteger, DateTime, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from ite_api.db.base import Base


class AuditLog(Base):
    __tablename__ = "audit_log"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    run_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True, index=True)  # FK added in Slice 3
    action: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    detail: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)
```

- [ ] **Step 6: Update `apps/api/ite_api/db/models/__init__.py`**

```python
from ite_api.db.models.audit_log import AuditLog
from ite_api.db.models.password_reset import PasswordReset
from ite_api.db.models.session import Session
from ite_api.db.models.user import User

__all__ = ["AuditLog", "PasswordReset", "Session", "User"]
```

- [ ] **Step 7: Run tests — verify model tests pass**

```bash
.venv/bin/pytest tests/test_models.py -v
```

Expected: 2 passed.

- [ ] **Step 8: Generate the Alembic migration**

```bash
# Start a throwaway postgres for autogenerate
docker run -d --rm --name ite-tmp-pg -e POSTGRES_PASSWORD=ite -e POSTGRES_USER=ite -e POSTGRES_DB=ite -p 5499:5432 postgres:16-alpine
sleep 3
ITE_DATABASE_URL="postgresql+psycopg://ite:ite@localhost:5499/ite" \
  ITE_JWT_SECRET=tmp \
  .venv/bin/alembic revision --autogenerate -m "initial auth schema"
docker stop ite-tmp-pg
```

Expected: a new file `alembic/versions/<hash>_initial_auth_schema.py` is created with `op.create_table('users', ...)`, etc.

Rename the generated file to `0001_initial_auth_schema.py` and confirm its `revision` line still matches the hash inside the file body. (Alembic uses the in-file `revision = '...'` string, not the filename, for ordering.)

- [ ] **Step 9: Verify the migration applies cleanly**

```bash
docker run -d --rm --name ite-tmp-pg -e POSTGRES_PASSWORD=ite -e POSTGRES_USER=ite -e POSTGRES_DB=ite -p 5499:5432 postgres:16-alpine
sleep 3
ITE_DATABASE_URL="postgresql+psycopg://ite:ite@localhost:5499/ite" \
  ITE_JWT_SECRET=tmp \
  .venv/bin/alembic upgrade head
docker stop ite-tmp-pg
```

Expected: `INFO  [alembic.runtime.migration] Running upgrade  -> 0001, initial auth schema` (no errors).

- [ ] **Step 10: Commit**

```bash
git add apps/api/ite_api/db/models apps/api/alembic/versions apps/api/tests/test_models.py
git commit -m "feat(api): add User, Session, PasswordReset, AuditLog models + initial migration"
```

---

## Task 4: Argon2 password hashing utility

**Files:**
- Create: `apps/api/ite_api/auth/__init__.py`
- Create: `apps/api/ite_api/auth/passwords.py`
- Create: `apps/api/tests/auth/__init__.py`
- Create: `apps/api/tests/auth/test_passwords.py`

- [ ] **Step 1: Write the failing test**

`apps/api/tests/auth/__init__.py`: empty.

`apps/api/tests/auth/test_passwords.py`:

```python
import pytest

from ite_api.auth.passwords import hash_password, verify_password


def test_hash_password_is_argon2id():
    h = hash_password("correct horse battery staple")
    assert h.startswith("$argon2id$")


def test_verify_password_round_trip():
    h = hash_password("hunter2-very-long-password")
    assert verify_password("hunter2-very-long-password", h) is True
    assert verify_password("wrong", h) is False


def test_hashes_are_unique_per_call():
    a = hash_password("same-password-each-time-please")
    b = hash_password("same-password-each-time-please")
    assert a != b


def test_verify_handles_invalid_hash_gracefully():
    assert verify_password("anything", "not-a-real-hash") is False
```

Run: `.venv/bin/pytest tests/auth/test_passwords.py -v`
Expected: `ModuleNotFoundError: No module named 'ite_api.auth'`.

- [ ] **Step 2: Create `apps/api/ite_api/auth/__init__.py`** (empty file).

- [ ] **Step 3: Create `apps/api/ite_api/auth/passwords.py`**

```python
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerifyMismatchError

# Spec §5: argon2id, t=3, m=64MB, p=4
_hasher = PasswordHasher(time_cost=3, memory_cost=64 * 1024, parallelism=4)


def hash_password(plaintext: str) -> str:
    return _hasher.hash(plaintext)


def verify_password(plaintext: str, hashed: str) -> bool:
    try:
        return _hasher.verify(hashed, plaintext)
    except (VerifyMismatchError, InvalidHashError, Exception):
        return False
```

- [ ] **Step 4: Run the tests — verify pass**

```bash
.venv/bin/pytest tests/auth/test_passwords.py -v
```

Expected: 4 passed.

- [ ] **Step 5: Commit**

```bash
git add apps/api/ite_api/auth apps/api/tests/auth
git commit -m "feat(api): add argon2id password hashing utility"
```

---

## Task 5: JWT access token + opaque refresh token utilities

**Files:**
- Create: `apps/api/ite_api/auth/tokens.py`
- Create: `apps/api/tests/auth/test_tokens.py`

- [ ] **Step 1: Write the failing test**

`apps/api/tests/auth/test_tokens.py`:

```python
import time

import pytest

from ite_api.auth.tokens import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    hash_refresh_token,
)


def test_access_token_round_trip(monkeypatch):
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    token = create_access_token(user_id="abc-123", role="admin")
    claims = decode_access_token(token)
    assert claims["sub"] == "abc-123"
    assert claims["role"] == "admin"


def test_access_token_rejects_wrong_secret(monkeypatch):
    monkeypatch.setenv("ITE_JWT_SECRET", "secret-one-32-bytes-of-padding-aa")
    token = create_access_token(user_id="x", role="viewer")
    monkeypatch.setenv("ITE_JWT_SECRET", "secret-two-32-bytes-of-padding-aa")
    with pytest.raises(Exception):
        decode_access_token(token)


def test_refresh_token_is_unique_and_hashable():
    a = create_refresh_token()
    b = create_refresh_token()
    assert a != b
    assert len(a) >= 32
    assert hash_refresh_token(a) == hash_refresh_token(a)
    assert hash_refresh_token(a) != hash_refresh_token(b)
    assert len(hash_refresh_token(a)) == 64  # sha256 hex
```

Run: `.venv/bin/pytest tests/auth/test_tokens.py -v`
Expected: collection error — `ite_api.auth.tokens` not found.

- [ ] **Step 2: Create `apps/api/ite_api/auth/tokens.py`**

```python
import hashlib
import secrets
from datetime import datetime, timedelta, timezone

import jwt

from ite_api.config import get_settings


def create_access_token(*, user_id: str, role: str) -> str:
    s = get_settings()
    now = datetime.now(timezone.utc)
    claims = {
        "sub": user_id,
        "role": role,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=s.access_token_minutes)).timestamp()),
    }
    return jwt.encode(claims, s.jwt_secret, algorithm="HS256")


def decode_access_token(token: str) -> dict:
    s = get_settings()
    return jwt.decode(token, s.jwt_secret, algorithms=["HS256"])


def create_refresh_token() -> str:
    return secrets.token_urlsafe(32)  # ~43 chars, 256 bits of entropy


def hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
```

- [ ] **Step 3: Run the tests — verify pass**

```bash
.venv/bin/pytest tests/auth/test_tokens.py -v
```

Expected: 3 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/auth/tokens.py apps/api/tests/auth/test_tokens.py
git commit -m "feat(api): add JWT access + opaque refresh token utilities"
```

---

## Task 6: Audit log helper

**Files:**
- Create: `apps/api/ite_api/audit.py`
- Create: `apps/api/tests/test_audit.py`

- [ ] **Step 1: Write the failing test**

`apps/api/tests/test_audit.py`:

```python
import uuid

from ite_api.audit import write_audit
from ite_api.db.models import AuditLog, User


def test_write_audit_inserts_row(db_session):
    u = User(email="x@x.co", password_hash="h", full_name="X", role="admin")
    db_session.add(u)
    db_session.flush()
    write_audit(db_session, user_id=u.id, action="test.action", detail={"k": "v"})
    db_session.flush()
    row = db_session.query(AuditLog).one()
    assert row.action == "test.action"
    assert row.detail == {"k": "v"}
    assert row.user_id == u.id


def test_write_audit_accepts_none_user(db_session):
    write_audit(db_session, user_id=None, action="anon.event", detail=None)
    db_session.flush()
    row = db_session.query(AuditLog).one()
    assert row.user_id is None
    assert row.detail is None
```

Run: `.venv/bin/pytest tests/test_audit.py -v` → fails (`ite_api.audit` not found).

- [ ] **Step 2: Create `apps/api/ite_api/audit.py`**

```python
import uuid

from sqlalchemy.orm import Session

from ite_api.db.models import AuditLog


def write_audit(
    db: Session,
    *,
    user_id: uuid.UUID | None,
    action: str,
    detail: dict | None = None,
    run_id: uuid.UUID | None = None,
) -> None:
    db.add(AuditLog(user_id=user_id, action=action, detail=detail, run_id=run_id))
```

- [ ] **Step 3: Verify tests pass**

```bash
.venv/bin/pytest tests/test_audit.py -v
```

Expected: 2 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/audit.py apps/api/tests/test_audit.py
git commit -m "feat(api): add audit log helper"
```

---

## Task 7: Lockout (failed-login throttling)

**Files:**
- Create: `apps/api/ite_api/auth/lockout.py`
- Create: `apps/api/tests/auth/test_lockout.py`

- [ ] **Step 1: Write the failing test**

`apps/api/tests/auth/test_lockout.py`:

```python
from ite_api.auth.lockout import is_locked_out, record_failed_attempt
from ite_api.db.models import AuditLog


def test_below_threshold_not_locked(db_session):
    for _ in range(9):
        record_failed_attempt(db_session, email="a@b.co")
    db_session.flush()
    assert is_locked_out(db_session, email="a@b.co") is False


def test_at_threshold_is_locked(db_session):
    for _ in range(10):
        record_failed_attempt(db_session, email="a@b.co")
    db_session.flush()
    assert is_locked_out(db_session, email="a@b.co") is True


def test_lockout_is_email_scoped(db_session):
    for _ in range(10):
        record_failed_attempt(db_session, email="a@b.co")
    db_session.flush()
    assert is_locked_out(db_session, email="other@b.co") is False


def test_record_writes_audit_row(db_session):
    record_failed_attempt(db_session, email="a@b.co")
    db_session.flush()
    rows = db_session.query(AuditLog).filter_by(action="login.failed").all()
    assert len(rows) == 1
    assert rows[0].detail == {"email": "a@b.co"}
```

Run: fails (module missing).

- [ ] **Step 2: Create `apps/api/ite_api/auth/lockout.py`**

```python
from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ite_api.audit import write_audit
from ite_api.config import get_settings
from ite_api.db.models import AuditLog


def record_failed_attempt(db: Session, *, email: str) -> None:
    write_audit(db, user_id=None, action="login.failed", detail={"email": email.lower()})


def is_locked_out(db: Session, *, email: str) -> bool:
    s = get_settings()
    window_start = datetime.now(timezone.utc) - timedelta(minutes=s.lockout_window_minutes)
    stmt = (
        select(func.count(AuditLog.id))
        .where(AuditLog.action == "login.failed")
        .where(AuditLog.at >= window_start)
        .where(AuditLog.detail["email"].astext == email.lower())
    )
    count = db.execute(stmt).scalar_one()
    return count >= s.lockout_max_attempts
```

- [ ] **Step 3: Verify tests pass**

```bash
.venv/bin/pytest tests/auth/test_lockout.py -v
```

Expected: 4 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/auth/lockout.py apps/api/tests/auth/test_lockout.py
git commit -m "feat(api): add per-email login lockout"
```

---

## Task 8: `current_user` dependency

**Files:**
- Create: `apps/api/ite_api/auth/dependencies.py`
- Create: `apps/api/tests/auth/test_dependencies.py`

- [ ] **Step 1: Write the failing test**

`apps/api/tests/auth/test_dependencies.py`:

```python
import uuid

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from ite_api.auth.dependencies import current_user, require_role
from ite_api.auth.tokens import create_access_token
from ite_api.db.models import User
from ite_api.db.session import get_session


@pytest.fixture()
def app_with_deps(engine):
    from sqlalchemy.orm import sessionmaker
    SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)

    def override_session():
        with SessionLocal() as s:
            yield s

    app = FastAPI()

    @app.get("/whoami")
    def whoami(user: User = current_user):
        return {"email": user.email}

    @app.get("/admin-only")
    def admin_only(user: User = require_role("admin")):
        return {"ok": True}

    app.dependency_overrides[get_session] = override_session
    return app


def test_missing_cookie_returns_401(app_with_deps):
    c = TestClient(app_with_deps)
    r = c.get("/whoami")
    assert r.status_code == 401


def test_valid_cookie_returns_user(app_with_deps, db_session, monkeypatch):
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    u = User(email="x@x.co", password_hash="h", full_name="X", role="engineer")
    db_session.add(u)
    db_session.commit()
    tok = create_access_token(user_id=str(u.id), role="engineer")
    c = TestClient(app_with_deps)
    c.cookies.set("ite_at", tok)
    r = c.get("/whoami")
    assert r.status_code == 200
    assert r.json()["email"] == "x@x.co"


def test_require_role_rejects_lower_role(app_with_deps, db_session, monkeypatch):
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    u = User(email="v@v.co", password_hash="h", full_name="V", role="viewer")
    db_session.add(u)
    db_session.commit()
    tok = create_access_token(user_id=str(u.id), role="viewer")
    c = TestClient(app_with_deps)
    c.cookies.set("ite_at", tok)
    r = c.get("/admin-only")
    assert r.status_code == 403
```

Run: fails (module missing).

- [ ] **Step 2: Create `apps/api/ite_api/auth/dependencies.py`**

```python
import uuid

from fastapi import Cookie, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ite_api.auth.tokens import decode_access_token
from ite_api.config import get_settings
from ite_api.db.models import User
from ite_api.db.session import get_session

_ROLE_RANK = {"viewer": 1, "engineer": 2, "admin": 3}


def _current_user_impl(
    db: Session = Depends(get_session),
    ite_at: str | None = Cookie(default=None),
) -> User:
    if not ite_at:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="not authenticated")
    try:
        claims = decode_access_token(ite_at)
    except Exception as e:  # noqa: BLE001 — any JWT error is a 401
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="invalid token") from e
    user = db.get(User, uuid.UUID(claims["sub"]))
    if user is None or user.disabled:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="user not found or disabled")
    return user


current_user = Depends(_current_user_impl)


def require_role(min_role: str):
    required = _ROLE_RANK[min_role]

    def _dep(user: User = Depends(_current_user_impl)) -> User:
        if _ROLE_RANK.get(user.role, 0) < required:
            raise HTTPException(status.HTTP_403_FORBIDDEN, detail="insufficient role")
        return user

    return Depends(_dep)
```

- [ ] **Step 3: Verify tests pass**

```bash
.venv/bin/pytest tests/auth/test_dependencies.py -v
```

Expected: 3 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/auth/dependencies.py apps/api/tests/auth/test_dependencies.py
git commit -m "feat(api): add current_user + require_role dependencies"
```

---

## Task 9: `POST /api/auth/login` route + cookie issuance

**Files:**
- Create: `apps/api/ite_api/routes/__init__.py`
- Create: `apps/api/ite_api/routes/auth.py`
- Modify: `apps/api/ite_api/main.py` (wire the router)
- Create: `apps/api/tests/routes/__init__.py`
- Create: `apps/api/tests/routes/test_auth.py` (login-only tests for this task; logout/me follow in later tasks)

- [ ] **Step 1: Write the failing test**

`apps/api/tests/routes/__init__.py`: empty.

`apps/api/tests/routes/test_auth.py`:

```python
from ite_api.auth.passwords import hash_password
from ite_api.db.models import User


def _make_user(db, email="admin@ite.local", role="admin", password="hunter2-long-enough"):
    u = User(email=email, password_hash=hash_password(password), full_name="A", role=role)
    db.add(u)
    db.commit()
    return u


def test_login_sets_cookies_and_returns_204(client, db_session):
    _make_user(db_session, email="a@b.co", password="hunter2-long-enough")
    r = client.post("/api/auth/login", json={"email": "a@b.co", "password": "hunter2-long-enough"})
    assert r.status_code == 204
    cookies = r.cookies
    assert "ite_at" in cookies
    assert "ite_rt" in cookies


def test_login_wrong_password_returns_401(client, db_session):
    _make_user(db_session, email="a@b.co", password="hunter2-long-enough")
    r = client.post("/api/auth/login", json={"email": "a@b.co", "password": "wrong"})
    assert r.status_code == 401


def test_login_unknown_email_returns_401(client):
    r = client.post("/api/auth/login", json={"email": "ghost@b.co", "password": "whatever-long"})
    assert r.status_code == 401


def test_login_email_is_case_insensitive(client, db_session):
    _make_user(db_session, email="mixed@b.co", password="hunter2-long-enough")
    r = client.post("/api/auth/login", json={"email": "MIXED@B.co", "password": "hunter2-long-enough"})
    assert r.status_code == 204
```

Run: fails (route does not exist → 404).

- [ ] **Step 2: Create `apps/api/ite_api/routes/__init__.py`** (empty).

- [ ] **Step 3: Create `apps/api/ite_api/routes/auth.py`**

```python
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Response, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ite_api.audit import write_audit
from ite_api.auth.lockout import is_locked_out, record_failed_attempt
from ite_api.auth.passwords import verify_password
from ite_api.auth.tokens import (
    create_access_token,
    create_refresh_token,
    hash_refresh_token,
)
from ite_api.config import get_settings
from ite_api.db.models import Session as UserSession
from ite_api.db.models import User
from ite_api.db.session import get_session

router = APIRouter(prefix="/api/auth", tags=["auth"])


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


def _set_auth_cookies(response: Response, *, access: str, refresh: str) -> None:
    s = get_settings()
    response.set_cookie(
        key=s.cookie_access_name,
        value=access,
        max_age=s.access_token_minutes * 60,
        httponly=True,
        secure=s.cookie_secure,
        samesite=s.cookie_samesite,
        path="/",
    )
    response.set_cookie(
        key=s.cookie_refresh_name,
        value=refresh,
        max_age=s.refresh_token_days * 24 * 60 * 60,
        httponly=True,
        secure=s.cookie_secure,
        samesite=s.cookie_samesite,
        path="/",
    )


@router.post("/login", status_code=status.HTTP_204_NO_CONTENT)
def login(payload: LoginRequest, response: Response, db: Session = Depends(get_session)):
    email = payload.email.lower()

    if is_locked_out(db, email=email):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, detail="too many failed attempts")

    user = db.execute(select(User).where(func.lower(User.email) == email)).scalar_one_or_none()
    if user is None or user.disabled or not verify_password(payload.password, user.password_hash):
        record_failed_attempt(db, email=email)
        db.commit()
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="invalid credentials")

    s = get_settings()
    refresh = create_refresh_token()
    db.add(UserSession(
        user_id=user.id,
        token_hash=hash_refresh_token(refresh),
        expires_at=datetime.now(timezone.utc) + timedelta(days=s.refresh_token_days),
    ))
    user.last_login_at = datetime.now(timezone.utc)
    write_audit(db, user_id=user.id, action="login", detail={"email": email})
    db.commit()

    access = create_access_token(user_id=str(user.id), role=user.role)
    _set_auth_cookies(response, access=access, refresh=refresh)
    return Response(status_code=status.HTTP_204_NO_CONTENT, headers=dict(response.headers))
```

- [ ] **Step 4: Wire the router in `apps/api/ite_api/main.py`**

Replace the file with:

```python
from fastapi import FastAPI

from ite_api.config import get_settings
from ite_api.routes.auth import router as auth_router


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="ITE Calibration API", version="0.1.0")

    @app.get("/api/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    app.include_router(auth_router)
    app.state.settings = settings
    return app


app = create_app()
```

- [ ] **Step 5: Verify tests pass**

```bash
.venv/bin/pytest tests/routes/test_auth.py -v
```

Expected: 4 passed.

- [ ] **Step 6: Commit**

```bash
git add apps/api/ite_api/routes apps/api/ite_api/main.py apps/api/tests/routes
git commit -m "feat(api): add POST /api/auth/login with cookie session"
```

---

## Task 10: Refresh middleware (silent rotation on expired access token)

**Files:**
- Create: `apps/api/ite_api/middleware/__init__.py`
- Create: `apps/api/ite_api/middleware/refresh.py`
- Modify: `apps/api/ite_api/main.py` (install middleware)
- Add tests to: `apps/api/tests/routes/test_auth.py`

- [ ] **Step 1: Add the failing test**

Append to `apps/api/tests/routes/test_auth.py`:

```python
import time
from datetime import datetime, timedelta, timezone

from ite_api.auth.tokens import create_refresh_token, hash_refresh_token
from ite_api.db.models import Session as UserSession


def test_expired_access_is_silently_rotated(client, db_session, monkeypatch):
    monkeypatch.setenv("ITE_ACCESS_TOKEN_MINUTES", "0")  # immediate expiry
    u = _make_user(db_session, email="r@b.co", password="hunter2-long-enough")
    rt = create_refresh_token()
    db_session.add(UserSession(
        user_id=u.id,
        token_hash=hash_refresh_token(rt),
        expires_at=datetime.now(timezone.utc) + timedelta(days=14),
    ))
    db_session.commit()
    client.cookies.set("ite_at", "expired.garbage.token")
    client.cookies.set("ite_rt", rt)
    r = client.get("/api/auth/me")
    assert r.status_code == 200
    # cookies were rotated
    assert "ite_at" in r.cookies
    assert "ite_rt" in r.cookies
    assert r.cookies["ite_rt"] != rt


def test_invalid_refresh_returns_401(client):
    client.cookies.set("ite_at", "expired")
    client.cookies.set("ite_rt", "not-a-real-token")
    r = client.get("/api/auth/me")
    assert r.status_code == 401
```

Run: these fail because `/api/auth/me` doesn't exist yet AND middleware doesn't exist.

- [ ] **Step 2: Create `apps/api/ite_api/middleware/__init__.py`** (empty).

- [ ] **Step 3: Create `apps/api/ite_api/middleware/refresh.py`**

```python
from datetime import datetime, timedelta, timezone

import jwt
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from ite_api.auth.tokens import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    hash_refresh_token,
)
from ite_api.config import get_settings
from ite_api.db.models import Session as UserSession
from ite_api.db.models import User
from ite_api.db.session import _init, _SessionLocal


class RefreshMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        s = get_settings()
        at = request.cookies.get(s.cookie_access_name)
        rt = request.cookies.get(s.cookie_refresh_name)
        rotated: tuple[str, str] | None = None

        if at:
            try:
                decode_access_token(at)
                return await call_next(request)
            except jwt.ExpiredSignatureError:
                pass  # try refresh below
            except Exception:
                return await call_next(request)

        if rt is not None:
            rotated = self._rotate(rt)
            if rotated:
                new_at, new_rt = rotated
                # inject new cookie into the request so downstream sees auth
                new_cookie_header = (
                    f"{s.cookie_access_name}={new_at}; {s.cookie_refresh_name}={new_rt}"
                )
                # rebuild headers
                hdrs = [(k, v) for k, v in request.scope["headers"] if k != b"cookie"]
                hdrs.append((b"cookie", new_cookie_header.encode()))
                request.scope["headers"] = hdrs

        response: Response = await call_next(request)

        if rotated:
            new_at, new_rt = rotated
            response.set_cookie(s.cookie_access_name, new_at, max_age=s.access_token_minutes * 60,
                                httponly=True, secure=s.cookie_secure, samesite=s.cookie_samesite, path="/")
            response.set_cookie(s.cookie_refresh_name, new_rt, max_age=s.refresh_token_days * 24 * 60 * 60,
                                httponly=True, secure=s.cookie_secure, samesite=s.cookie_samesite, path="/")
        return response

    def _rotate(self, presented_rt: str) -> tuple[str, str] | None:
        _init()
        assert _SessionLocal is not None
        s = get_settings()
        token_hash = hash_refresh_token(presented_rt)
        with _SessionLocal() as db:
            sess = db.query(UserSession).filter_by(token_hash=token_hash).one_or_none()
            now = datetime.now(timezone.utc)
            if sess is None or sess.revoked_at is not None or sess.expires_at < now:
                return None
            user = db.get(User, sess.user_id)
            if user is None or user.disabled:
                return None
            # rotate
            new_rt = create_refresh_token()
            sess.token_hash = hash_refresh_token(new_rt)
            sess.expires_at = now + timedelta(days=s.refresh_token_days)
            db.commit()
            new_at = create_access_token(user_id=str(user.id), role=user.role)
            return new_at, new_rt
```

- [ ] **Step 4: Install middleware in `apps/api/ite_api/main.py`**

Replace the file with:

```python
from fastapi import FastAPI

from ite_api.config import get_settings
from ite_api.middleware.refresh import RefreshMiddleware
from ite_api.routes.auth import router as auth_router


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="ITE Calibration API", version="0.1.0")
    app.add_middleware(RefreshMiddleware)

    @app.get("/api/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    app.include_router(auth_router)
    app.state.settings = settings
    return app


app = create_app()
```

- [ ] **Step 5: Run the new tests — they should fail only on the missing `/me` route**

```bash
.venv/bin/pytest tests/routes/test_auth.py -v 2>&1 | tail -10
```

Expected: the two new tests fail with 404 (route `/api/auth/me` not yet defined). Continue to Task 11.

- [ ] **Step 6: Commit**

```bash
git add apps/api/ite_api/middleware apps/api/ite_api/main.py apps/api/tests/routes/test_auth.py
git commit -m "feat(api): add refresh middleware with silent token rotation"
```

---

## Task 11: `POST /api/auth/logout` + `GET /api/auth/me`

**Files:**
- Modify: `apps/api/ite_api/routes/auth.py`

- [ ] **Step 1: Add tests for logout to `tests/routes/test_auth.py`**

Append:

```python
def test_logout_clears_cookies_and_revokes_session(client, db_session):
    _make_user(db_session, email="o@b.co", password="hunter2-long-enough")
    client.post("/api/auth/login", json={"email": "o@b.co", "password": "hunter2-long-enough"})
    r = client.post("/api/auth/logout")
    assert r.status_code == 204
    # Subsequent /me must be 401
    r2 = client.get("/api/auth/me")
    assert r2.status_code == 401


def test_me_returns_user(client, db_session):
    _make_user(db_session, email="m@b.co", role="engineer", password="hunter2-long-enough")
    client.post("/api/auth/login", json={"email": "m@b.co", "password": "hunter2-long-enough"})
    r = client.get("/api/auth/me")
    assert r.status_code == 200
    body = r.json()
    assert body["email"] == "m@b.co"
    assert body["role"] == "engineer"
    assert "id" in body
```

Run → fails (routes missing).

- [ ] **Step 2: Append to `apps/api/ite_api/routes/auth.py`**

Add the imports at top (alongside existing):

```python
from ite_api.auth.dependencies import current_user
```

Append to the end of the file:

```python
class MeResponse(BaseModel):
    id: str
    email: str
    full_name: str
    role: str


@router.get("/me", response_model=MeResponse)
def me(user: User = current_user) -> MeResponse:
    return MeResponse(id=str(user.id), email=user.email, full_name=user.full_name, role=user.role)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(response: Response, db: Session = Depends(get_session), ite_rt: str | None = None):
    from fastapi import Cookie  # local import to keep the original header

    return _logout_impl(response, db, ite_rt)


def _logout_impl(response: Response, db: Session, ite_rt: str | None) -> Response:
    s = get_settings()
    if ite_rt:
        sess = db.query(UserSession).filter_by(token_hash=hash_refresh_token(ite_rt)).one_or_none()
        if sess and sess.revoked_at is None:
            sess.revoked_at = datetime.now(timezone.utc)
            write_audit(db, user_id=sess.user_id, action="logout", detail=None)
            db.commit()
    out = Response(status_code=status.HTTP_204_NO_CONTENT)
    out.delete_cookie(s.cookie_access_name, path="/")
    out.delete_cookie(s.cookie_refresh_name, path="/")
    return out
```

Replace the `logout` route signature properly — the local `from fastapi import Cookie` trick above is ugly. Use this cleaner version instead:

```python
@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(
    db: Session = Depends(get_session),
    ite_rt: str | None = Cookie(default=None),
) -> Response:
    s = get_settings()
    if ite_rt:
        sess = db.query(UserSession).filter_by(token_hash=hash_refresh_token(ite_rt)).one_or_none()
        if sess and sess.revoked_at is None:
            sess.revoked_at = datetime.now(timezone.utc)
            write_audit(db, user_id=sess.user_id, action="logout", detail=None)
            db.commit()
    out = Response(status_code=status.HTTP_204_NO_CONTENT)
    out.delete_cookie(s.cookie_access_name, path="/")
    out.delete_cookie(s.cookie_refresh_name, path="/")
    return out
```

And add `from fastapi import Cookie` to the top imports.

- [ ] **Step 3: Verify all auth route tests pass**

```bash
.venv/bin/pytest tests/routes/test_auth.py -v
```

Expected: all tests in the file pass (login × 4, refresh × 2, logout, me — 8 total).

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/routes/auth.py apps/api/tests/routes/test_auth.py
git commit -m "feat(api): add /api/auth/me and /api/auth/logout"
```

---

## Task 12: Origin header check middleware on mutating routes

**Files:**
- Create: `apps/api/ite_api/middleware/origin.py`
- Modify: `apps/api/ite_api/main.py`
- Create: `apps/api/tests/middleware/__init__.py`
- Create: `apps/api/tests/middleware/test_origin.py`

- [ ] **Step 1: Write the failing test**

`apps/api/tests/middleware/__init__.py`: empty.

`apps/api/tests/middleware/test_origin.py`:

```python
def test_post_without_origin_header_is_rejected(client):
    r = client.post("/api/auth/login", json={"email": "a@b.co", "password": "x" * 20}, headers={"Origin": ""})
    # Empty Origin → rejected
    assert r.status_code == 400


def test_post_with_allowed_origin_passes(client, monkeypatch):
    monkeypatch.setenv("ITE_ALLOWED_ORIGINS", "http://localhost")
    r = client.post("/api/auth/login",
                    json={"email": "a@b.co", "password": "x" * 20},
                    headers={"Origin": "http://localhost"})
    # 401 because bad credentials, but middleware let it through
    assert r.status_code in (401, 429)


def test_get_does_not_require_origin(client):
    r = client.get("/api/health")
    assert r.status_code == 200
```

- [ ] **Step 2: Extend `Settings` in `apps/api/ite_api/config.py`**

Add the field:

```python
    allowed_origins: str = "http://localhost"  # comma-separated
```

- [ ] **Step 3: Create `apps/api/ite_api/middleware/origin.py`**

```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from ite_api.config import get_settings

_SAFE = {"GET", "HEAD", "OPTIONS"}


class OriginCheckMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        if request.method in _SAFE:
            return await call_next(request)
        s = get_settings()
        allowed = {o.strip() for o in s.allowed_origins.split(",") if o.strip()}
        origin = request.headers.get("origin", "")
        if not origin or origin not in allowed:
            return JSONResponse({"detail": "bad origin"}, status_code=400)
        return await call_next(request)
```

- [ ] **Step 4: Install in `apps/api/ite_api/main.py`**

Replace with:

```python
from fastapi import FastAPI

from ite_api.config import get_settings
from ite_api.middleware.origin import OriginCheckMiddleware
from ite_api.middleware.refresh import RefreshMiddleware
from ite_api.routes.auth import router as auth_router


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="ITE Calibration API", version="0.1.0")
    app.add_middleware(RefreshMiddleware)
    app.add_middleware(OriginCheckMiddleware)

    @app.get("/api/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    app.include_router(auth_router)
    app.state.settings = settings
    return app


app = create_app()
```

- [ ] **Step 5: Fix existing auth tests to send Origin header**

Edit `apps/api/tests/conftest.py` `client` fixture — append before `yield c`:

```python
        c.headers["Origin"] = "http://localhost"
```

So the final fixture body becomes:

```python
    monkeypatch.setenv("ITE_DATABASE_URL", postgres_url)
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    monkeypatch.setenv("ITE_ALLOWED_ORIGINS", "http://localhost")
    from ite_api.main import create_app
    app = create_app()
    with TestClient(app) as c:
        c.headers["Origin"] = "http://localhost"
        yield c
```

- [ ] **Step 6: Verify all tests still pass**

```bash
.venv/bin/pytest -v
```

Expected: all green (the origin tests use explicit overrides where they need different headers).

- [ ] **Step 7: Commit**

```bash
git add apps/api/ite_api/middleware/origin.py apps/api/ite_api/main.py apps/api/ite_api/config.py apps/api/tests
git commit -m "feat(api): add Origin header check on mutating routes"
```

---

## Task 13: `create-admin` CLI command

**Files:**
- Create: `apps/api/ite_api/cli.py`
- Create: `apps/api/tests/test_cli.py`
- Modify: `apps/api/pyproject.toml` (add console script)

- [ ] **Step 1: Add console script to `pyproject.toml`**

Append:

```toml
[project.scripts]
ite-api = "ite_api.cli:app"
```

- [ ] **Step 2: Write the failing test**

`apps/api/tests/test_cli.py`:

```python
from typer.testing import CliRunner

from ite_api.cli import app as cli_app
from ite_api.db.models import User


def test_create_admin_inserts_user(engine, monkeypatch, postgres_url):
    monkeypatch.setenv("ITE_DATABASE_URL", postgres_url)
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    runner = CliRunner()
    result = runner.invoke(cli_app, [
        "create-admin",
        "--email", "boss@ite.local",
        "--full-name", "Boss",
        "--password", "hunter2-long-enough",
    ])
    assert result.exit_code == 0, result.output
    from sqlalchemy.orm import sessionmaker
    SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    with SessionLocal() as s:
        u = s.query(User).filter_by(email="boss@ite.local").one()
        assert u.role == "admin"
        assert u.password_hash.startswith("$argon2id$")
```

- [ ] **Step 3: Reinstall the package so the console script registers**

```bash
.venv/bin/pip install -e . --quiet
```

- [ ] **Step 4: Create `apps/api/ite_api/cli.py`**

```python
import typer

from ite_api.auth.passwords import hash_password
from ite_api.db.models import User
from ite_api.db.session import _init, _SessionLocal

app = typer.Typer(help="ITE Calibration API CLI")


@app.command("create-admin")
def create_admin(
    email: str = typer.Option(..., "--email"),
    full_name: str = typer.Option(..., "--full-name"),
    password: str = typer.Option(..., "--password", help="min 12 chars"),
) -> None:
    if len(password) < 12:
        raise typer.BadParameter("password must be at least 12 characters")
    _init()
    assert _SessionLocal is not None
    with _SessionLocal() as db:
        if db.query(User).filter_by(email=email.lower()).first():
            raise typer.BadParameter(f"user {email} already exists")
        db.add(User(
            email=email.lower(),
            full_name=full_name,
            password_hash=hash_password(password),
            role="admin",
        ))
        db.commit()
    typer.echo(f"Created admin {email}")
```

- [ ] **Step 5: Verify the test passes**

```bash
.venv/bin/pytest tests/test_cli.py -v
```

Expected: 1 passed.

- [ ] **Step 6: Commit**

```bash
git add apps/api/ite_api/cli.py apps/api/tests/test_cli.py apps/api/pyproject.toml
git commit -m "feat(api): add create-admin CLI command"
```

---

## Task 14: Add Postgres service to CI for the api job

**Files:**
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Update `.github/workflows/ci.yml`** — replace the `api:` job with:

```yaml
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
        env:
          ITE_JWT_SECRET: ci-test-secret-not-real
          ITE_ALLOWED_ORIGINS: http://localhost
        run: pytest -v
```

The `testcontainers` fixture spins up its own Postgres via Docker inside the GitHub Actions runner, so we don't need a CI service container. Verify Docker is available on `ubuntu-latest` (it is by default).

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: pass ITE_JWT_SECRET + allowed origins to api test job"
```

---

## Task 15: Frontend dependencies + design tokens + fonts

**Files:**
- Modify: `apps/web/package.json`
- Create: `apps/web/src/theme/tokens.css`
- Create: `apps/web/src/theme/reset.css`
- Modify: `apps/web/index.html` (preconnect + IBM Plex)
- Modify: `apps/web/src/main.tsx` (import CSS)

- [ ] **Step 1: Add dependencies to `apps/web/package.json`**

Replace `dependencies` and `devDependencies` with:

```json
  "dependencies": {
    "@tanstack/react-query": "5.62.7",
    "lucide-react": "0.469.0",
    "react": "18.3.1",
    "react-dom": "18.3.1",
    "react-hook-form": "7.54.2",
    "react-router-dom": "6.28.1",
    "zod": "3.24.1"
  },
  "devDependencies": {
    "@playwright/test": "1.49.1",
    "@testing-library/jest-dom": "6.6.3",
    "@testing-library/react": "16.1.0",
    "@testing-library/user-event": "14.5.2",
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
```

Run:

```bash
cd apps/web && npm install
```

- [ ] **Step 2: Create `apps/web/src/theme/reset.css`**

```css
*, *::before, *::after { box-sizing: border-box; }
html, body, #root { height: 100%; }
body {
  margin: 0;
  font-family: var(--font-sans);
  color: var(--c-text);
  background: var(--c-bg);
  -webkit-font-smoothing: antialiased;
}
a { color: inherit; text-decoration: none; }
button { font: inherit; cursor: pointer; }
```

- [ ] **Step 3: Create `apps/web/src/theme/tokens.css`**

```css
:root {
  --c-accent-50:  #ecfdf5;
  --c-accent-100: #d1fae5;
  --c-accent-300: #6ee7b7;
  --c-accent-500: #10b981;
  --c-accent-600: #059669;
  --c-accent-700: #047857;
  --c-accent-900: #064e3b;

  --c-bg:        #f7faf9;
  --c-surface:   #ffffff;
  --c-border:    #e5ebe9;
  --c-text:      #0f1f1a;
  --c-text-soft: #5a6b66;
  --c-text-mute: #8a9994;

  --c-pass: var(--c-accent-600);
  --c-warn: #d97706;
  --c-fail: #b91c1c;
  --c-info: #1d4ed8;

  --font-sans: "IBM Plex Sans", "Segoe UI", "San Francisco", system-ui, sans-serif;
  --font-mono: "IBM Plex Mono", ui-monospace, monospace;

  --s-1: 4px; --s-2: 8px; --s-3: 12px; --s-4: 16px;
  --s-5: 24px; --s-6: 32px; --s-8: 48px;

  --radius-sm: 4px; --radius-md: 6px; --radius-lg: 10px;
  --shadow-1: 0 1px 2px rgba(15,31,26,.06);
  --shadow-2: 0 4px 12px rgba(15,31,26,.08);
}
```

- [ ] **Step 4: Update `apps/web/index.html`**

Replace with:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>ITE Calibration</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      rel="stylesheet"
      href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@400;500;600;700&display=swap"
    />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 5: Update `apps/web/src/main.tsx` to import the CSS**

```tsx
import React from "react";
import ReactDOM from "react-dom/client";

import "./theme/tokens.css";
import "./theme/reset.css";

import App from "./App";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
```

- [ ] **Step 6: Verify build and tests still work**

```bash
npm test && npm run build
```

Expected: tests pass, build outputs `dist/`.

- [ ] **Step 7: Commit**

```bash
git add apps/web/package.json apps/web/package-lock.json apps/web/src/theme apps/web/index.html apps/web/src/main.tsx
git commit -m "feat(web): add router/query/RHF/zod deps + IBM Plex theme tokens"
```

---

## Task 16: Typed API client with 401 silent-refresh

**Files:**
- Create: `apps/web/src/api/types.ts`
- Create: `apps/web/src/api/client.ts`
- Create: `apps/web/src/api/client.test.ts`

- [ ] **Step 1: Write the failing test**

`apps/web/src/api/client.test.ts`:

```ts
import { describe, expect, it, vi } from "vitest";

import { apiFetch, ApiError } from "./client";

describe("apiFetch", () => {
  it("returns parsed JSON on 200", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ status: "ok" }),
    } as Response);
    const data = await apiFetch<{ status: string }>("/api/health");
    expect(data).toEqual({ status: "ok" });
  });

  it("throws ApiError on non-OK", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 401,
      json: async () => ({ detail: "nope" }),
    } as Response);
    await expect(apiFetch("/api/auth/me")).rejects.toBeInstanceOf(ApiError);
  });

  it("sends credentials include", async () => {
    const f = vi.fn().mockResolvedValue({
      ok: true, status: 200, json: async () => ({}),
    } as Response);
    global.fetch = f;
    await apiFetch("/api/health");
    expect(f).toHaveBeenCalledWith("/api/health", expect.objectContaining({ credentials: "include" }));
  });
});
```

Run: `npm test` → fails (`./client` not found).

- [ ] **Step 2: Create `apps/web/src/api/types.ts`**

```ts
export type Role = "admin" | "engineer" | "viewer";

export interface AuthMe {
  id: string;
  email: string;
  full_name: string;
  role: Role;
}
```

- [ ] **Step 3: Create `apps/web/src/api/client.ts`**

```ts
export class ApiError extends Error {
  status: number;
  detail: unknown;
  constructor(status: number, detail: unknown) {
    super(`ApiError ${status}`);
    this.status = status;
    this.detail = detail;
  }
}

type Init = Omit<RequestInit, "body"> & { json?: unknown };

export async function apiFetch<T>(path: string, init: Init = {}): Promise<T> {
  const { json, headers, ...rest } = init;
  const finalHeaders: HeadersInit = {
    ...(json !== undefined ? { "Content-Type": "application/json" } : {}),
    ...headers,
  };
  const resp = await fetch(path, {
    credentials: "include",
    ...rest,
    headers: finalHeaders,
    body: json !== undefined ? JSON.stringify(json) : (rest as RequestInit).body,
  });
  if (!resp.ok) {
    let detail: unknown = null;
    try {
      detail = await resp.json();
    } catch { /* ignore */ }
    throw new ApiError(resp.status, detail);
  }
  if (resp.status === 204) return undefined as T;
  return (await resp.json()) as T;
}
```

- [ ] **Step 4: Verify tests pass**

```bash
npm test
```

Expected: existing App test + 3 client tests = 4 passed.

- [ ] **Step 5: Commit**

```bash
git add apps/web/src/api
git commit -m "feat(web): add typed fetch client with ApiError"
```

---

## Task 17: AuthProvider, useAuth, RequireAuth

**Files:**
- Create: `apps/web/src/auth/AuthProvider.tsx`
- Create: `apps/web/src/auth/useAuth.ts`
- Create: `apps/web/src/auth/RequireAuth.tsx`
- Create: `apps/web/src/auth/AuthProvider.test.tsx`

- [ ] **Step 1: Write the failing test**

`apps/web/src/auth/AuthProvider.test.tsx`:

```tsx
import { render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { AuthProvider } from "./AuthProvider";
import { useAuth } from "./useAuth";

function Probe() {
  const { user, loading } = useAuth();
  if (loading) return <p>loading</p>;
  return <p>{user ? `user:${user.email}` : "anon"}</p>;
}

describe("AuthProvider", () => {
  it("shows loading then anon on 401", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false, status: 401, json: async () => ({}),
    } as Response);
    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    );
    expect(screen.getByText("loading")).toBeInTheDocument();
    await waitFor(() => expect(screen.getByText("anon")).toBeInTheDocument());
  });

  it("shows user when /me returns 200", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true, status: 200,
      json: async () => ({ id: "1", email: "x@y", full_name: "X", role: "admin" }),
    } as Response);
    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    );
    await waitFor(() => expect(screen.getByText("user:x@y")).toBeInTheDocument());
  });
});
```

Run → fails (modules missing).

- [ ] **Step 2: Create `apps/web/src/auth/AuthProvider.tsx`**

```tsx
import { createContext, useCallback, useEffect, useMemo, useState, type ReactNode } from "react";

import { apiFetch, ApiError } from "../api/client";
import type { AuthMe } from "../api/types";

interface AuthContextValue {
  user: AuthMe | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  refresh: () => Promise<void>;
}

export const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthMe | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    try {
      const me = await apiFetch<AuthMe>("/api/auth/me");
      setUser(me);
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) setUser(null);
      else throw e;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh().catch(() => setLoading(false));
  }, [refresh]);

  const login = useCallback(async (email: string, password: string) => {
    await apiFetch<void>("/api/auth/login", { method: "POST", json: { email, password } });
    await refresh();
  }, [refresh]);

  const logout = useCallback(async () => {
    await apiFetch<void>("/api/auth/logout", { method: "POST" });
    setUser(null);
  }, []);

  const value = useMemo(() => ({ user, loading, login, logout, refresh }), [user, loading, login, logout, refresh]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
```

- [ ] **Step 3: Create `apps/web/src/auth/useAuth.ts`**

```ts
import { useContext } from "react";

import { AuthContext } from "./AuthProvider";

export function useAuth() {
  const v = useContext(AuthContext);
  if (!v) throw new Error("useAuth must be used inside <AuthProvider>");
  return v;
}
```

- [ ] **Step 4: Create `apps/web/src/auth/RequireAuth.tsx`**

```tsx
import type { ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";

import { useAuth } from "./useAuth";

export function RequireAuth({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();
  const loc = useLocation();
  if (loading) return <p style={{ padding: 24 }}>Loading…</p>;
  if (!user) return <Navigate to="/login" state={{ from: loc.pathname }} replace />;
  return <>{children}</>;
}
```

- [ ] **Step 5: Verify tests pass**

```bash
npm test
```

Expected: AuthProvider tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/web/src/auth
git commit -m "feat(web): add AuthProvider, useAuth, RequireAuth"
```

---

## Task 18: LoginPage

**Files:**
- Create: `apps/web/src/pages/LoginPage.tsx`
- Create: `apps/web/src/pages/LoginPage.module.css`
- Create: `apps/web/src/pages/LoginPage.test.tsx`

- [ ] **Step 1: Write the failing test**

`apps/web/src/pages/LoginPage.test.tsx`:

```tsx
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it, vi } from "vitest";

import { AuthProvider } from "../auth/AuthProvider";
import { LoginPage } from "./LoginPage";

function wrap() {
  return render(
    <MemoryRouter>
      <AuthProvider>
        <LoginPage />
      </AuthProvider>
    </MemoryRouter>,
  );
}

describe("LoginPage", () => {
  it("shows email + password fields and a submit button", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false, status: 401, json: async () => ({}),
    } as Response);
    wrap();
    await waitFor(() => screen.getByRole("button", { name: /sign in/i }));
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
  });

  it("shows validation error for invalid email", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false, status: 401, json: async () => ({}),
    } as Response);
    wrap();
    const user = userEvent.setup();
    await user.click(await screen.findByRole("button", { name: /sign in/i }));
    expect(await screen.findByText(/valid email/i)).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Create `apps/web/src/pages/LoginPage.module.css`**

```css
.wrap {
  display: grid;
  place-items: center;
  min-height: 100vh;
  padding: var(--s-5);
}

.card {
  width: 100%;
  max-width: 380px;
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-2);
  padding: var(--s-6);
}

.title { margin: 0 0 var(--s-2); font-size: 22px; }
.subtitle { margin: 0 0 var(--s-5); color: var(--c-text-soft); font-size: 14px; }

.field { display: block; margin-bottom: var(--s-4); }
.label { display: block; font-size: 13px; color: var(--c-text-soft); margin-bottom: var(--s-1); }
.input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-md);
  font-size: 14px;
}
.input:focus { outline: 2px solid var(--c-accent-500); outline-offset: -1px; border-color: transparent; }

.button {
  width: 100%;
  background: var(--c-accent-600);
  color: white;
  border: 0;
  border-radius: var(--radius-md);
  padding: 10px 12px;
  font-weight: 600;
}
.button:hover { background: var(--c-accent-700); }
.button:disabled { opacity: .6; cursor: not-allowed; }

.error { color: var(--c-fail); font-size: 13px; margin-top: var(--s-1); }
```

- [ ] **Step 3: Create `apps/web/src/pages/LoginPage.tsx`**

```tsx
import { useState } from "react";
import { useForm } from "react-hook-form";
import { useLocation, useNavigate } from "react-router-dom";
import { z } from "zod";

import { ApiError } from "../api/client";
import { useAuth } from "../auth/useAuth";
import styles from "./LoginPage.module.css";

const Schema = z.object({
  email: z.string().email("Enter a valid email"),
  password: z.string().min(1, "Required"),
});
type FormValues = z.infer<typeof Schema>;

interface LocationState { from?: string }

export function LoginPage() {
  const { login } = useAuth();
  const nav = useNavigate();
  const loc = useLocation();
  const [submitErr, setSubmitErr] = useState<string | null>(null);

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormValues>();

  const onSubmit = async (raw: FormValues) => {
    setSubmitErr(null);
    const parsed = Schema.safeParse(raw);
    if (!parsed.success) {
      setSubmitErr(parsed.error.issues[0]?.message ?? "Invalid input");
      return;
    }
    try {
      await login(parsed.data.email, parsed.data.password);
      const next = (loc.state as LocationState | null)?.from ?? "/";
      nav(next, { replace: true });
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) setSubmitErr("Invalid email or password.");
      else if (e instanceof ApiError && e.status === 429) setSubmitErr("Too many attempts. Try again later.");
      else setSubmitErr("Something went wrong.");
    }
  };

  return (
    <main className={styles.wrap}>
      <form className={styles.card} onSubmit={handleSubmit(onSubmit)} noValidate>
        <h1 className={styles.title}>ITE Calibration</h1>
        <p className={styles.subtitle}>Sign in to continue</p>

        <label className={styles.field}>
          <span className={styles.label}>Email</span>
          <input className={styles.input} type="email" autoComplete="email"
                 aria-label="Email" {...register("email")} />
          {errors.email && <div className={styles.error}>{errors.email.message}</div>}
        </label>

        <label className={styles.field}>
          <span className={styles.label}>Password</span>
          <input className={styles.input} type="password" autoComplete="current-password"
                 aria-label="Password" {...register("password")} />
          {errors.password && <div className={styles.error}>{errors.password.message}</div>}
        </label>

        {submitErr && <div className={styles.error} role="alert">{submitErr}</div>}

        <button className={styles.button} disabled={isSubmitting} type="submit">
          Sign in
        </button>
      </form>
    </main>
  );
}
```

- [ ] **Step 4: Verify tests pass**

```bash
npm test
```

Expected: LoginPage tests pass.

- [ ] **Step 5: Commit**

```bash
git add apps/web/src/pages/LoginPage.tsx apps/web/src/pages/LoginPage.module.css apps/web/src/pages/LoginPage.test.tsx
git commit -m "feat(web): add LoginPage with RHF + zod validation"
```

---

## Task 19: AppShell (Sidebar + Topbar) and route table with "Coming soon" stubs

**Files:**
- Create: `apps/web/src/components/AppShell.tsx`
- Create: `apps/web/src/components/AppShell.module.css`
- Create: `apps/web/src/components/Sidebar.tsx`
- Create: `apps/web/src/components/Topbar.tsx`
- Create: `apps/web/src/components/ComingSoon.tsx`
- Create: `apps/web/src/pages/OverviewPage.tsx`
- Create: `apps/web/src/pages/NewCalibrationPage.tsx`
- Create: `apps/web/src/pages/HistoryPage.tsx`
- Create: `apps/web/src/pages/RunDetailPage.tsx`
- Create: `apps/web/src/pages/UpcomingPage.tsx`
- Create: `apps/web/src/pages/LoggerProfilePage.tsx`
- Create: `apps/web/src/pages/CertificatePage.tsx`
- Create: `apps/web/src/pages/SettingsPage.tsx`
- Replace: `apps/web/src/App.tsx`
- Replace: `apps/web/src/App.test.tsx` (route the test through the new shell)

- [ ] **Step 1: Create `apps/web/src/components/ComingSoon.tsx`**

```tsx
export function ComingSoon({ name }: { name: string }) {
  return (
    <section style={{ padding: 32 }}>
      <h2 style={{ marginTop: 0 }}>{name}</h2>
      <p style={{ color: "var(--c-text-soft)" }}>Coming in a later slice.</p>
    </section>
  );
}
```

- [ ] **Step 2: Create the page stubs** — each file:

`apps/web/src/pages/OverviewPage.tsx`:

```tsx
export function OverviewPage() {
  return (
    <section style={{ padding: 32 }}>
      <h2 style={{ marginTop: 0 }}>Overview</h2>
      <p style={{ color: "var(--c-text-soft)" }}>Dashboard tiles arrive in Slice 5.</p>
    </section>
  );
}
```

`apps/web/src/pages/NewCalibrationPage.tsx`:

```tsx
import { ComingSoon } from "../components/ComingSoon";
export function NewCalibrationPage() { return <ComingSoon name="New Calibration" />; }
```

Repeat with the appropriate display name for: `HistoryPage` ("Calibrations"), `RunDetailPage` ("Run detail"), `UpcomingPage` ("Upcoming"), `LoggerProfilePage` ("Logger profile"), `CertificatePage` ("Certificate"), `SettingsPage` ("Settings").

- [ ] **Step 3: Create `apps/web/src/components/AppShell.module.css`**

```css
.shell { display: grid; grid-template-columns: 240px 1fr; min-height: 100vh; }
.sidebar {
  background: var(--c-accent-900);
  color: var(--c-accent-50);
  padding: var(--s-5) var(--s-4);
}
.brand { font-weight: 700; font-size: 16px; margin-bottom: var(--s-6); letter-spacing: .2px; }
.navItem {
  display: block;
  padding: 8px 10px;
  border-radius: var(--radius-md);
  color: var(--c-accent-100);
  font-size: 14px;
  margin-bottom: 2px;
}
.navItem:hover { background: rgba(255,255,255,.06); }
.navItemActive { background: var(--c-accent-700); color: white; }
.main { display: flex; flex-direction: column; }
.topbar {
  height: 56px;
  border-bottom: 1px solid var(--c-border);
  background: var(--c-surface);
  display: flex; align-items: center; justify-content: space-between;
  padding: 0 var(--s-5);
}
.userPill {
  font-size: 13px; color: var(--c-text-soft);
  display: flex; gap: var(--s-3); align-items: center;
}
.logout {
  background: transparent; border: 1px solid var(--c-border);
  padding: 6px 10px; border-radius: var(--radius-md); font-size: 13px;
}
.logout:hover { border-color: var(--c-accent-500); color: var(--c-accent-700); }
.content { flex: 1; overflow: auto; }
```

- [ ] **Step 4: Create `apps/web/src/components/Sidebar.tsx`**

```tsx
import { NavLink } from "react-router-dom";

import styles from "./AppShell.module.css";

const NAV: { to: string; label: string }[] = [
  { to: "/", label: "Overview" },
  { to: "/calibrations", label: "Calibrations" },
  { to: "/upcoming", label: "Upcoming" },
  { to: "/new", label: "New calibration" },
  { to: "/loggers", label: "Logger profile" },
  { to: "/certificate", label: "Certificate" },
  { to: "/settings", label: "Settings" },
];

export function Sidebar() {
  return (
    <aside className={styles.sidebar}>
      <div className={styles.brand}>ITE Calibration</div>
      {NAV.map((n) => (
        <NavLink
          key={n.to}
          to={n.to}
          end={n.to === "/"}
          className={({ isActive }) =>
            isActive ? `${styles.navItem} ${styles.navItemActive}` : styles.navItem
          }
        >
          {n.label}
        </NavLink>
      ))}
    </aside>
  );
}
```

- [ ] **Step 5: Create `apps/web/src/components/Topbar.tsx`**

```tsx
import { useNavigate } from "react-router-dom";

import { useAuth } from "../auth/useAuth";
import styles from "./AppShell.module.css";

export function Topbar() {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  return (
    <header className={styles.topbar}>
      <div style={{ fontWeight: 600 }}>Dashboard</div>
      <div className={styles.userPill}>
        <span>{user?.full_name} · {user?.role}</span>
        <button
          className={styles.logout}
          onClick={async () => { await logout(); nav("/login", { replace: true }); }}
        >Log out</button>
      </div>
    </header>
  );
}
```

- [ ] **Step 6: Create `apps/web/src/components/AppShell.tsx`**

```tsx
import { Outlet } from "react-router-dom";

import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";
import styles from "./AppShell.module.css";

export function AppShell() {
  return (
    <div className={styles.shell}>
      <Sidebar />
      <div className={styles.main}>
        <Topbar />
        <div className={styles.content}>
          <Outlet />
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 7: Replace `apps/web/src/App.tsx`**

```tsx
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";

import { AppShell } from "./components/AppShell";
import { AuthProvider } from "./auth/AuthProvider";
import { RequireAuth } from "./auth/RequireAuth";

import { CertificatePage } from "./pages/CertificatePage";
import { HistoryPage } from "./pages/HistoryPage";
import { LoggerProfilePage } from "./pages/LoggerProfilePage";
import { LoginPage } from "./pages/LoginPage";
import { NewCalibrationPage } from "./pages/NewCalibrationPage";
import { OverviewPage } from "./pages/OverviewPage";
import { RunDetailPage } from "./pages/RunDetailPage";
import { SettingsPage } from "./pages/SettingsPage";
import { UpcomingPage } from "./pages/UpcomingPage";

const qc = new QueryClient();

export default function App() {
  return (
    <QueryClientProvider client={qc}>
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<RequireAuth><AppShell /></RequireAuth>}>
              <Route index element={<OverviewPage />} />
              <Route path="calibrations" element={<HistoryPage />} />
              <Route path="calibrations/:id" element={<RunDetailPage />} />
              <Route path="upcoming" element={<UpcomingPage />} />
              <Route path="new" element={<NewCalibrationPage />} />
              <Route path="loggers" element={<LoggerProfilePage />} />
              <Route path="certificate" element={<CertificatePage />} />
              <Route path="settings" element={<SettingsPage />} />
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
```

- [ ] **Step 8: Replace `apps/web/src/App.test.tsx`**

```tsx
import { render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import App from "./App";

describe("App", () => {
  it("renders login page when unauthenticated", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false, status: 401, json: async () => ({}),
    } as Response);
    render(<App />);
    await waitFor(() => expect(screen.getByText(/sign in to continue/i)).toBeInTheDocument());
  });
});
```

- [ ] **Step 9: Verify tests + build pass**

```bash
npm test && npm run build
```

Expected: all tests pass; build succeeds.

- [ ] **Step 10: Commit**

```bash
git add apps/web/src
git commit -m "feat(web): add AppShell + Sidebar + Topbar + page stubs + route table"
```

---

## Task 20: Playwright e2e — login → overview → logout

**Files:**
- Create: `apps/web/playwright.config.ts`
- Create: `apps/web/e2e/auth.spec.ts`
- Modify: `apps/web/package.json` (add `e2e` script)

- [ ] **Step 1: Add `e2e` script**

In `apps/web/package.json` `scripts`, add:

```json
    "e2e": "playwright test"
```

- [ ] **Step 2: Install Playwright browsers**

```bash
npx playwright install --with-deps chromium
```

- [ ] **Step 3: Create `apps/web/playwright.config.ts`**

```ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  use: {
    baseURL: process.env.BASE_URL ?? "http://localhost",
    headless: true,
  },
});
```

- [ ] **Step 4: Create `apps/web/e2e/auth.spec.ts`**

```ts
import { expect, test } from "@playwright/test";

const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? "boss@ite.local";
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? "hunter2-very-long-password";

test("admin can log in, see overview, and log out", async ({ page }) => {
  await page.goto("/login");
  await expect(page.getByText(/sign in to continue/i)).toBeVisible();

  await page.getByLabel(/email/i).fill(ADMIN_EMAIL);
  await page.getByLabel(/password/i).fill(ADMIN_PASSWORD);
  await page.getByRole("button", { name: /sign in/i }).click();

  await expect(page).toHaveURL("/");
  await expect(page.getByRole("heading", { name: /overview/i })).toBeVisible();

  await page.getByRole("button", { name: /log out/i }).click();
  await expect(page).toHaveURL(/\/login$/);
});
```

- [ ] **Step 5: Document e2e usage in `README.md`** — append:

```markdown
## End-to-end tests

```bash
cd infra && docker compose --env-file .env up -d --build
cd ../apps/api && \
  ITE_DATABASE_URL="postgresql+psycopg://ite:changeme@localhost:5432/ite" \
  ITE_JWT_SECRET=dev-only-change-me-32-chars-min-please \
  .venv/bin/alembic upgrade head
.venv/bin/ite-api create-admin --email boss@ite.local --full-name Boss --password hunter2-very-long-password
cd ../web && BASE_URL=http://localhost npm run e2e
cd ../../infra && docker compose --env-file .env down
```
```

NB: we don't run e2e in CI for Slice 1 — it requires the full Docker stack and a seeded user. Local-only for now.

- [ ] **Step 6: Commit**

```bash
git add apps/web/playwright.config.ts apps/web/e2e apps/web/package.json README.md
git commit -m "test(web): add Playwright e2e for login -> overview -> logout"
```

---

## Task 21: README update for Slice 1 + final verification

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the "Slice 0 (current)" section to "Slice 1 (current)"**

Replace the entire "Slice 0 (current): Skeleton" section in `README.md` with:

```markdown
## Slice 1 (current): Auth + AppShell

What works after this slice:

- Admin user created via CLI: `ite-api create-admin --email ... --full-name ... --password ...`
- Login at `http://localhost/login` (email + password), session cookies set.
- Authenticated routes show the AppShell (green sidebar + topbar) with placeholder pages.
- `GET /api/auth/me` returns the current user; logout revokes the session.
- Refresh middleware silently rotates the access token when it expires.
- Lockout after 10 failed logins per email in 15 min.
- Origin header check on all mutating routes.
- CI runs lint + tests for both apps (api tests use `testcontainers` Postgres).

What doesn't work yet: any calibration features. Those arrive in Slice 2 (engine) and Slice 3 (New Calibration end-to-end).
```

- [ ] **Step 2: Add a "First-time setup" subsection under Quickstart**

Append to `README.md`:

```markdown
## First-time setup

After `docker compose up`, create the first admin:

```bash
cd apps/api && \
  ITE_DATABASE_URL="postgresql+psycopg://ite:changeme@localhost:5432/ite" \
  ITE_JWT_SECRET=dev-only-change-me-32-chars-min-please \
  .venv/bin/alembic upgrade head
ITE_DATABASE_URL=... ITE_JWT_SECRET=... .venv/bin/ite-api create-admin \
  --email you@ite.local --full-name "You" --password "at-least-twelve-chars"
```

Then log in at http://localhost/login.
```

- [ ] **Step 3: Final verification**

```bash
# API
(cd apps/api && ITE_JWT_SECRET=test-secret .venv/bin/pytest -v)
# Web
(cd apps/web && npm test && npm run build)
# Stack smoke
(cd infra && docker compose --env-file .env up -d --build)
sleep 8
curl -sS http://localhost/api/health
# Apply migration into the compose Postgres + create admin
docker compose -f infra/docker-compose.yml --env-file infra/.env exec -T api \
  alembic upgrade head
docker compose -f infra/docker-compose.yml --env-file infra/.env exec -T api \
  ite-api create-admin --email demo@ite.local --full-name Demo --password "demo-password-12345"
# Try login from a real curl with cookie jar
curl -c /tmp/ck -sS -X POST http://localhost/api/auth/login \
  -H "Content-Type: application/json" -H "Origin: http://localhost" \
  -d '{"email":"demo@ite.local","password":"demo-password-12345"}' -o /dev/null -w "%{http_code}\n"
curl -b /tmp/ck -sS http://localhost/api/auth/me
(cd infra && docker compose --env-file .env down)
```

Expected: pytest green, vitest green, build green; health → `{"status":"ok"}`; login → 204; `/me` → JSON with `"email":"demo@ite.local"`.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: update README for Slice 1 (auth + appshell)"
```

---

## Self-review notes

- **Spec coverage:**
  - Two-token cookie auth (§5) — Tasks 5, 9, 10.
  - argon2id (§5) — Task 4.
  - Refresh rotation (§5) — Task 10.
  - Roles + dependency guard (§5) — Task 8.
  - Lockout (§5) — Task 7 (utility) + Task 9 (gate in login route).
  - Origin header check (§5) — Task 12.
  - `users`/`sessions`/`password_resets` tables (§6 Slice 1) — Task 3.
  - `audit_log` (pulled forward from §6 Slice 3) — Task 3.
  - `POST /auth/login` / `/logout` / `GET /auth/me` (§3) — Tasks 9, 11.
  - CLI `create-admin` (§6 Slice 1) — Task 13.
  - Frontend AuthProvider / RequireAuth / LoginPage / AppShell (§4) — Tasks 16, 17, 18, 19.
  - Design tokens, IBM Plex, green-dominant palette (§4) — Task 15.
  - Deferred pages as stubs (§6 Slice 1) — Task 19.
  - e2e happy path (§6 Testing) — Task 20.
- **No placeholders:** every step includes exact file contents or commands.
- **Type consistency:** `ite_at` / `ite_rt`, `create_access_token` / `decode_access_token`, `hash_refresh_token`, `current_user` / `require_role`, `useAuth`, `RequireAuth`, `AppShell` are used identically across tasks.
- **Deferred (explicit, not gaps):** admin user-management routes (`POST /auth/users`, `PATCH /auth/users/{id}`) — Slice 6 per spec. Password-reset email flow (token shown to admin manually) — Slice 6 per spec. We added the `password_resets` table but no routes use it yet.
