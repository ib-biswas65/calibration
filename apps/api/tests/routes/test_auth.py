from ite_api.auth.passwords import hash_password
from ite_api.db.models import User


def _make_user(db, email="admin@ite.local", role="admin", password="hunter2-long-enough"):
    u = User(email=email, password_hash=hash_password(password), full_name="A", role=role)
    db.add(u)
    db.commit()
    return u


def test_login_sets_cookies_and_returns_204(client, db_session):
    _make_user(db_session, email="a@b.co", password="hunter2-long-enough")
    r = client.post(
        "/api/auth/login",
        json={"email": "a@b.co", "password": "hunter2-long-enough"},
    )
    assert r.status_code == 204
    cookies = r.cookies
    assert "ite_at" in cookies
    assert "ite_rt" in cookies


def test_login_wrong_password_returns_401(client, db_session):
    _make_user(db_session, email="a@b.co", password="hunter2-long-enough")
    r = client.post(
        "/api/auth/login",
        json={"email": "a@b.co", "password": "wrong-and-also-long-enough"},
    )
    assert r.status_code == 401


def test_login_unknown_email_returns_401(client):
    r = client.post(
        "/api/auth/login",
        json={"email": "ghost@b.co", "password": "whatever-long-enough"},
    )
    assert r.status_code == 401


def test_login_email_is_case_insensitive(client, db_session):
    _make_user(db_session, email="mixed@b.co", password="hunter2-long-enough")
    r = client.post(
        "/api/auth/login",
        json={"email": "MIXED@B.co", "password": "hunter2-long-enough"},
    )
    assert r.status_code == 204


def test_logout_clears_cookies_and_revokes_session(client, db_session):
    _make_user(db_session, email="o@b.co", password="hunter2-long-enough")
    client.post(
        "/api/auth/login",
        json={"email": "o@b.co", "password": "hunter2-long-enough"},
    )
    r = client.post("/api/auth/logout")
    assert r.status_code == 204
    r2 = client.get("/api/auth/me")
    assert r2.status_code == 401


def test_me_returns_user(client, db_session):
    _make_user(db_session, email="m@b.co", role="engineer", password="hunter2-long-enough")
    client.post(
        "/api/auth/login",
        json={"email": "m@b.co", "password": "hunter2-long-enough"},
    )
    r = client.get("/api/auth/me")
    assert r.status_code == 200
    body = r.json()
    assert body["email"] == "m@b.co"
    assert body["role"] == "engineer"
    assert "id" in body
