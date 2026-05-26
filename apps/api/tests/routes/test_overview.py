"""Integration tests for the overview route."""

import pytest

from ite_api.auth.passwords import hash_password
from ite_api.db.models import User


@pytest.fixture()
def viewer(db_session):
    u = User(
        email="viewer@example.com",
        full_name="Viewer",
        password_hash=hash_password("strongpassword12"),
        role="viewer",
    )
    db_session.add(u)
    db_session.commit()
    return u


def test_overview_empty(client, viewer):
    client.post("/api/auth/login", json={"email": "viewer@example.com", "password": "strongpassword12"})
    resp = client.get("/api/overview")
    assert resp.status_code == 200
    data = resp.json()
    assert data["fleet"]["total_loggers"] == 0
    assert data["last_30d"]["runs"] == 0
    assert data["recent_runs"] == []
    assert data["due_soon"] == []


def test_overview_requires_auth(client):
    resp = client.get("/api/overview")
    assert resp.status_code == 401
