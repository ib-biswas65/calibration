from sqlalchemy.orm import sessionmaker
from typer.testing import CliRunner

from ite_api.cli import app as cli_app
from ite_api.db import session as db_session_mod
from ite_api.db.models import User


def test_create_admin_inserts_user(engine, monkeypatch, postgres_url):
    monkeypatch.setenv("ITE_DATABASE_URL", postgres_url)
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    # reset module-level engine so the CLI re-inits against the test container
    db_session_mod._engine = None
    db_session_mod._SessionLocal = None
    runner = CliRunner()
    result = runner.invoke(cli_app, [
        "create-admin",
        "--email", "boss@ite.local",
        "--full-name", "Boss",
        "--password", "hunter2-long-enough",
    ])
    assert result.exit_code == 0, result.output
    SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    with SessionLocal() as s:
        u = s.query(User).filter_by(email="boss@ite.local").one()
        assert u.role == "admin"
        assert u.password_hash.startswith("$argon2id$")


def test_create_admin_rejects_short_password():
    runner = CliRunner()
    result = runner.invoke(cli_app, [
        "create-admin",
        "--email", "x@y.z",
        "--full-name", "X",
        "--password", "short",
    ])
    assert result.exit_code != 0
