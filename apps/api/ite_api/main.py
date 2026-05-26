from fastapi import FastAPI

from ite_api.config import get_settings
from ite_api.routes.auth import router as auth_router


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="ITE Calibration API", version="0.1.0")

    @app.get("/api/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    app.include_router(auth_router)
    app.state.settings = settings
    return app


app = create_app()
