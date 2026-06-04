from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session, sessionmaker
from testcontainers.postgres import PostgresContainer

from ite_api.db.base import Base


@pytest.fixture(scope="session")
def postgres_url() -> Iterator[str]:
    with PostgresContainer("postgres:16-alpine", driver="psycopg") as pg:
        yield pg.get_connection_url()


@pytest.fixture(scope="session")
def engine(postgres_url: str):
    import ite_api.db.models  # noqa: F401  ensure models register on Base.metadata

    eng = create_engine(postgres_url, future=True)
    Base.metadata.create_all(eng)
    yield eng
    eng.dispose()


@pytest.fixture()
def db_session(engine) -> Iterator[Session]:
    SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    with SessionLocal() as s:
        yield s
        s.rollback()
    with engine.begin() as conn:
        tables = ",".join(f'"{t.name}"' for t in reversed(Base.metadata.sorted_tables))
        if tables:
            conn.execute(text(f"TRUNCATE {tables} RESTART IDENTITY CASCADE"))


@pytest.fixture()
def client(postgres_url: str, engine, monkeypatch, tmp_path) -> Iterator[TestClient]:
    monkeypatch.setenv("ITE_DATABASE_URL", postgres_url)
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    monkeypatch.setenv("ITE_ALLOWED_ORIGINS", "http://localhost")
    monkeypatch.setenv("ITE_DATA_DIR", str(tmp_path / "data"))
    from ite_api.main import create_app
    app = create_app()
    with TestClient(app) as c:
        c.headers["Origin"] = "http://localhost"
        yield c
    # Truncate after each client test to keep isolation.
    with engine.begin() as conn:
        tables = ",".join(f'"{t.name}"' for t in reversed(Base.metadata.sorted_tables))
        if tables:
            conn.execute(text(f"TRUNCATE {tables} RESTART IDENTITY CASCADE"))
