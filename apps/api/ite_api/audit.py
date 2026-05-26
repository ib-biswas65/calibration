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
