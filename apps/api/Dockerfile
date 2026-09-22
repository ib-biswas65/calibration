FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY pyproject.toml ./
COPY ite_api ./ite_api
COPY alembic.ini ./alembic.ini
COPY alembic ./alembic
COPY docker-entrypoint.sh ./docker-entrypoint.sh

RUN pip install --upgrade pip && pip install . && chmod +x docker-entrypoint.sh

EXPOSE 8000
# WEB_CONCURRENCY can be overridden in docker-compose (default 2 — safe for a 4-core Windows PC).
# Each worker is an independent process with its own DB connection pool.
# Migrations run once in docker-entrypoint.sh, before workers start — see
# ite_api/migrate.py for why they must not run inside the app's lifespan.
ENTRYPOINT ["./docker-entrypoint.sh"]
