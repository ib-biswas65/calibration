from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="ITE_", env_file=None)

    env: str = "dev"
    database_url: str = "postgresql+psycopg://ite:ite@localhost:5432/ite"
    data_dir: Path = Path("/var/lib/ite-calibration/data")

    jwt_secret: str = "dev-only-change-me"
    access_token_minutes: int = 15
    refresh_token_days: int = 14
    cookie_access_name: str = "ite_at"
    cookie_refresh_name: str = "ite_rt"
    cookie_secure: bool = False
    cookie_samesite: str = "lax"

    lockout_max_attempts: int = 10
    lockout_window_minutes: int = 15
    lockout_cooldown_minutes: int = 15

    allowed_origins: str = "http://localhost"


def get_settings() -> Settings:
    return Settings()
