from ite_api.db.models import AuditLog, PasswordReset, User
from ite_api.db.models import Session as UserSession


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


def test_audit_log_jsonb_round_trip(db_session):
    db_session.add(AuditLog(action="x.y", detail={"k": "v", "n": 1}))
    db_session.flush()
    row = db_session.query(AuditLog).one()
    assert row.detail == {"k": "v", "n": 1}


def test_session_and_password_reset_models_exist():
    assert UserSession.__tablename__ == "sessions"
    assert PasswordReset.__tablename__ == "password_resets"
