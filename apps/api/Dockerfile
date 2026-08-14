FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY pyproject.toml ./
COPY ite_api ./ite_api
COPY alembic.ini ./alembic.ini
COPY alembic ./alembic

RUN pip install --upgrade pip && pip install .

EXPOSE 8000
# WEB_CONCURRENCY can be overridden in docker-compose (default 2 — safe for a 4-core Windows PC).
# Each worker is an independent process with its own DB connection pool.
CMD ["sh", "-c", "uvicorn ite_api.main:app --host 0.0.0.0 --port 8000 --workers ${WEB_CONCURRENCY:-2}"]
