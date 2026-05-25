FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY pyproject.toml ./
RUN pip install --upgrade pip && pip install .

COPY ite_api ./ite_api
COPY alembic.ini ./alembic.ini
COPY alembic ./alembic

EXPOSE 8000
CMD ["uvicorn", "ite_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
