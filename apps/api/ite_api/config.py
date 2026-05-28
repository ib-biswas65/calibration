from pathlib import Path

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_DEV_JWT_SECRET = "dev-only-change-me"
_DEV_DB_URL = "postgresql+psycopg://ite:ite@localhost:5432/ite"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="ITE_", env_file=None)

    env: str = "dev"
    database_url: str = _DEV_DB_URL
    data_dir: Path = Path("/var/lib/ite-calibration/data")

    jwt_secret: str = _DEV_JWT_SECRET
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

    @model_validator(mode="after")
    def _validate_production_secrets(self) -> "Settings":
        if self.env == "production":
            errors = []
            if self.jwt_secret == _DEV_JWT_SECRET:
                errors.append(
                    "ITE_JWT_SECRET is still the dev default. "
                    "Generate a strong secret: python3 -c \"import secrets; print(secrets.token_hex(32))\""
                )
            if "changeme" in self.database_url or self.database_url == _DEV_DB_URL:
                errors.append(
                    "ITE_DATABASE_URL contains a weak/default password. Set a strong POSTGRES_PASSWORD."
                )
            if errors:
                raise ValueError(
                    "Production startup blocked — insecure configuration detected:\n"
                    + "\n".join(f"  • {e}" for e in errors)
                )
        return self


def get_settings() -> Settings:
    return Settings()
