import logging
import logging.config
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import update

from ite_api.config import get_settings
from ite_api.middleware.origin import OriginCheckMiddleware
from ite_api.middleware.refresh import RefreshMiddleware
from ite_api.routes.auth import router as auth_router
from ite_api.routes.loggers import router as loggers_router
from ite_api.routes.overview import router as overview_router
from ite_api.routes.runs import router as runs_router
from ite_api.routes.users import router as users_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
)
_log = logging.getLogger(__name__)


def _recover_stuck_runs() -> None:
    """Reset any runs left in 'processing' from a previous crashed/restarted instance."""
    from ite_api.db.models.calibration import CalibrationRun
    from ite_api.db.session import _init, _SessionLocal

    _init()
    assert _SessionLocal is not None
    with _SessionLocal() as db:
        result = db.execute(
            update(CalibrationRun)
            .where(CalibrationRun.status == "processing")
            .values(
                status="failed",
                failure_reason={"message": "Processing was interrupted by a server restart. Please retry."},
            )
        )
        if result.rowcount:
            db.commit()
            _log.warning("Recovered %d stuck processing run(s) → 'failed'", result.rowcount)


@asynccontextmanager
async def lifespan(app: FastAPI):
    _recover_stuck_runs()
    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="ITE Calibration API", version="0.1.0", lifespan=lifespan)
    app.add_middleware(RefreshMiddleware)
    app.add_middleware(OriginCheckMiddleware)

    @app.get("/api/health")
    def health() -> dict:
        checks: dict[str, str] = {"api": "ok"}

        # Verify data directory is writable (catches full/mis-mounted volumes).
        probe = settings.data_dir / ".health_probe"
        try:
            settings.data_dir.mkdir(parents=True, exist_ok=True)
            probe.write_text("ok")
            probe.unlink()
            checks["storage"] = "ok"
        except OSError as e:
            checks["storage"] = f"error: {e}"

        overall = "ok" if all(v == "ok" for v in checks.values()) else "degraded"
        return {"status": overall, **checks}

    app.include_router(auth_router)
    app.include_router(users_router)
    app.include_router(runs_router)
    app.include_router(overview_router)
    app.include_router(loggers_router)
    app.state.settings = settings
    return app


app = create_app()
