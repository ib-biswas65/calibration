import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.orm import sessionmaker

from ite_api.auth.dependencies import current_user, require_role
from ite_api.auth.tokens import create_access_token
from ite_api.db.models import User
from ite_api.db.session import get_session


@pytest.fixture()
def app_with_deps(engine):
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


def test_missing_cookie_returns_401(app_with_deps, monkeypatch):
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
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
