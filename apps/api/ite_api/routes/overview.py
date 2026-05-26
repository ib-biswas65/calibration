"""GET /api/overview — dashboard aggregate stats."""

from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ite_api.auth.dependencies import current_user
from ite_api.db.models import User
from ite_api.db.models.calibration import CalibrationRun, Logger, LoggerResult
from ite_api.db.session import get_session

router = APIRouter(prefix="/api/overview", tags=["overview"])


class FleetStats(BaseModel):
    total_loggers: int
    due_30d: int
    overdue: int


class Last30dStats(BaseModel):
    runs: int
    pass_rate: float | None
    fail_count: int
    adjusted_count: int


class RecentRun(BaseModel):
    id: str
    batch_name: str
    status: str
    created_at: datetime
    verdict_mix: dict


class DueSoon(BaseModel):
    logger_id: str
    serial_no: str
    next_due_at: str | None


class OverviewResponse(BaseModel):
    fleet: FleetStats
    last_30d: Last30dStats
    recent_runs: list[RecentRun]
    due_soon: list[DueSoon]


@router.get("", response_model=OverviewResponse)
def get_overview(
    db: Session = Depends(get_session),
    user: User = current_user,
):
    now = datetime.now(UTC)
    cutoff_30d = now - timedelta(days=30)
    today = now.date()
    due_cutoff = (now + timedelta(days=30)).date()

    total_loggers = db.scalar(select(func.count()).select_from(Logger)) or 0
    due_30d = db.scalar(
        select(func.count()).select_from(Logger).where(
            Logger.next_due_at != None,  # noqa: E711
            Logger.next_due_at >= today,
            Logger.next_due_at <= due_cutoff,
        )
    ) or 0
    overdue = db.scalar(
        select(func.count()).select_from(Logger).where(
            Logger.next_due_at != None,  # noqa: E711
            Logger.next_due_at < today,
        )
    ) or 0

    recent_runs_rows = db.scalars(
        select(CalibrationRun)
        .where(CalibrationRun.created_at >= cutoff_30d)
        .order_by(CalibrationRun.created_at.desc())
        .limit(50)
    ).all()

    runs_30d = len(recent_runs_rows)
    all_results_30d = db.scalars(
        select(LoggerResult).join(
            CalibrationRun, LoggerResult.run_id == CalibrationRun.id
        ).where(CalibrationRun.created_at >= cutoff_30d)
    ).all()

    pass_count = sum(1 for r in all_results_30d if r.verdict == "pass")
    fail_count = sum(1 for r in all_results_30d if r.verdict == "fail")
    adj_count = sum(1 for r in all_results_30d if r.verdict == "adjusted")
    total_results = len(all_results_30d)
    pass_rate = (pass_count / total_results) if total_results > 0 else None

    recent_5 = recent_runs_rows[:5]
    recent_run_out = []
    for run in recent_5:
        results = db.scalars(select(LoggerResult).where(LoggerResult.run_id == run.id)).all()
        mix = {}
        for r in results:
            mix[r.verdict] = mix.get(r.verdict, 0) + 1
        recent_run_out.append(RecentRun(
            id=str(run.id),
            batch_name=run.batch_name,
            status=run.status,
            created_at=run.created_at,
            verdict_mix=mix,
        ))

    due_soon_loggers = db.scalars(
        select(Logger)
        .where(Logger.next_due_at != None, Logger.next_due_at >= today, Logger.next_due_at <= due_cutoff)  # noqa: E711
        .order_by(Logger.next_due_at)
        .limit(5)
    ).all()

    return OverviewResponse(
        fleet=FleetStats(total_loggers=total_loggers, due_30d=due_30d, overdue=overdue),
        last_30d=Last30dStats(runs=runs_30d, pass_rate=round(pass_rate * 100, 1) if pass_rate is not None else None,
                               fail_count=fail_count, adjusted_count=adj_count),
        recent_runs=recent_run_out,
        due_soon=[
            DueSoon(logger_id=str(lg.id), serial_no=lg.serial_no,
                    next_due_at=lg.next_due_at.isoformat() if lg.next_due_at else None)
            for lg in due_soon_loggers
        ],
    )
