"""Standalone Alembic migration runner.

Run this as a separate step BEFORE the app's uvicorn workers start (see
docker-entrypoint.sh), so the migration executes exactly once no matter how
many workers the container runs. Do NOT call this from inside the FastAPI
app's own lifespan/startup handler: with multiple uvicorn workers, each
worker process imports the app independently, so an in-app migration call
runs `alembic upgrade head` once per worker with no coordination between
them. That is a DDL operation, not safe under uncoordinated concurrent
execution, and it has caused a stuck alembic_version in production while
the app kept serving traffic against the stale schema.
"""

import logging

from alembic import command
from alembic.config import Config
from alembic.runtime.migration import MigrationContext
from alembic.script import ScriptDirectory
from sqlalchemy import create_engine

from ite_api.config import get_settings

_log = logging.getLogger(__name__)


def run_migrations() -> None:
    """Apply pending Alembic migrations and verify the DB actually reached head.

    Raises RuntimeError if `alembic upgrade head` returns without the
    database's alembic_version actually advancing to the expected head
    revision -- e.g. because the DB connection was killed mid-upgrade and
    the transaction rolled back after the "Running upgrade ..." log line
    was already emitted. A loud crash here is far better than the caller
    going on to serve traffic against a stale schema.
    """
    settings = get_settings()
    cfg = Config("/app/alembic.ini")
    cfg.set_main_option("sqlalchemy.url", settings.database_url)

    script = ScriptDirectory.from_config(cfg)
    head_revision = script.get_current_head()

    command.upgrade(cfg, "head")

    engine = create_engine(settings.database_url)
    try:
        with engine.connect() as conn:
            current_revision = MigrationContext.configure(conn).get_current_revision()
    finally:
        engine.dispose()

    if current_revision != head_revision:
        raise RuntimeError(
            "Migration did not reach head: alembic_version is "
            f"{current_revision!r}, expected {head_revision!r}. The upgrade "
            "command returned without raising but the database was not "
            "actually updated (e.g. the connection was killed mid-upgrade). "
            "Refusing to continue against a stale schema."
        )

    _log.info("Database migrations applied (head=%s).", head_revision)


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    )
    run_migrations()
