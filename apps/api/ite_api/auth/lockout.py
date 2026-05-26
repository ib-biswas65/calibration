from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ite_api.audit import write_audit
from ite_api.config import get_settings
from ite_api.db.models import AuditLog


def record_failed_attempt(db: Session, *, email: str) -> None:
    write_audit(db, user_id=None, action="login.failed", detail={"email": email.lower()})


def is_locked_out(db: Session, *, email: str) -> bool:
    s = get_settings()
    window_start = datetime.now(UTC) - timedelta(minutes=s.lockout_window_minutes)
    stmt = (
        select(func.count(AuditLog.id))
        .where(AuditLog.action == "login.failed")
        .where(AuditLog.at >= window_start)
        .where(AuditLog.detail["email"].astext == email.lower())
    )
    count = db.execute(stmt).scalar_one()
    return count >= s.lockout_max_attempts
