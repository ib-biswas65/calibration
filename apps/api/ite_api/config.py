from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="ITE_", env_file=None)

    env: str = "dev"
    database_url: str = "postgresql+psycopg://ite:ite@localhost:5432/ite"


def get_settings() -> Settings:
    return Settings()
