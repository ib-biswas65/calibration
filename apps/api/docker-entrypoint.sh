#!/bin/sh
# Runs database migrations exactly once, before any uvicorn worker starts.
# Migrations must not run inside the FastAPI app's own lifespan handler:
# with --workers > 1, each worker process would run `alembic upgrade head`
# concurrently with no coordination, which races the same DDL.
set -e

echo "Running database migrations..."
python -m ite_api.migrate

echo "Starting API server..."
exec uvicorn ite_api.main:app --host 0.0.0.0 --port 8000 --workers "${WEB_CONCURRENCY:-2}"
