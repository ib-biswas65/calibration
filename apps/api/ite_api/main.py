from fastapi import FastAPI

from ite_api.config import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="ITE Calibration API", version="0.1.0")

    @app.get("/api/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    app.state.settings = settings
    return app


app = create_app()
