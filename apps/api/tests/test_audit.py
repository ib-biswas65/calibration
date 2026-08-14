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
