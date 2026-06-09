from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from ite_api.config import get_settings

_engine = None
_SessionLocal: sessionmaker[Session] | None = None


def _init() -> None:
    global _engine, _SessionLocal
    if _engine is None:
        _engine = create_engine(
            get_settings().database_url,
            future=True,
            pool_size=5,
            max_overflow=10,
            pool_pre_ping=True,   # discard stale connections (important after idle/restart)
            pool_recycle=1800,    # recycle connections after 30 min
            pool_timeout=30,
            # Force UTF-8 on every connection — prevents multi-byte characters
            # (Japanese, special punctuation, etc.) from being silently corrupted to '?'.
            connect_args={"client_encoding": "utf8"},
        )
        _SessionLocal = sessionmaker(bind=_engine, autoflush=False, expire_on_commit=False)


def get_session() -> Iterator[Session]:
    _init()
    assert _SessionLocal is not None
    with _SessionLocal() as s:
        yield s
