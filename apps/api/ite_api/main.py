from fastapi import FastAPI

from ite_api.config import get_settings
from ite_api.middleware.origin import OriginCheckMiddleware
from ite_api.middleware.refresh import RefreshMiddleware
from ite_api.routes.auth import router as auth_router
from ite_api.routes.loggers import router as loggers_router
from ite_api.routes.overview import router as overview_router
from ite_api.routes.runs import router as runs_router
from ite_api.routes.users import router as users_router


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="ITE Calibration API", version="0.1.0")
    app.add_middleware(RefreshMiddleware)
    app.add_middleware(OriginCheckMiddleware)

    @app.get("/api/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    app.include_router(auth_router)
    app.include_router(users_router)
    app.include_router(runs_router)
    app.include_router(overview_router)
    app.include_router(loggers_router)
    app.state.settings = settings
    return app


app = create_app()
