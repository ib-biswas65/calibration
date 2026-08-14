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
