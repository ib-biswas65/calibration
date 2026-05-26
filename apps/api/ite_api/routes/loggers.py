"""Logger device routes — list and detail (v1 stubs with real data)."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from ite_api.auth.dependencies import current_user
from ite_api.db.models import User
from ite_api.db.models.calibration import Logger, LoggerResult
from ite_api.db.session import get_session

router = APIRouter(prefix="/api/loggers", tags=["loggers"])


class LoggerSummary(BaseModel):
    id: str
    serial_no: str
    model: str | None
    notes: str | None
    next_due_at: str | None

    model_config = {"from_attributes": True}


@router.get("", response_model=list[LoggerSummary])
def list_loggers(
    q: str | None = Query(default=None),
    limit: int = Query(default=50, le=200),
    db: Session = Depends(get_session),
    user: User = current_user,
):
    stmt = select(Logger).order_by(Logger.serial_no).limit(limit)
    if q:
        stmt = stmt.where(Logger.serial_no.ilike(f"%{q}%"))
    loggers = db.scalars(stmt).all()
    return [
        LoggerSummary(
            id=str(lg.id),
            serial_no=lg.serial_no,
            model=lg.model,
            notes=lg.notes,
            next_due_at=lg.next_due_at.isoformat() if lg.next_due_at else None,
        )
        for lg in loggers
    ]


@router.get("/{logger_id}")
def get_logger(
    logger_id: uuid.UUID,
    db: Session = Depends(get_session),
    user: User = current_user,
):
    lg = db.get(Logger, logger_id)
    if lg is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="logger not found")
    results = db.scalars(select(LoggerResult).where(LoggerResult.logger_id == logger_id)
                         .order_by(LoggerResult.created_at.desc()).limit(20)).all()
    return {
        "id": str(lg.id),
        "serial_no": lg.serial_no,
        "model": lg.model,
        "notes": lg.notes,
        "next_due_at": lg.next_due_at.isoformat() if lg.next_due_at else None,
        "history": [
            {
                "result_id": str(r.id),
                "run_id": str(r.run_id),
                "verdict": r.verdict,
                "max_deviation_c": float(r.max_deviation_c) if r.max_deviation_c is not None else None,
                "cert_no": r.cert_no,
                "created_at": r.created_at.isoformat(),
            }
            for r in results
        ],
    }
