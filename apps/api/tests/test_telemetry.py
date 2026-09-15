"""Confirm the app starts and serves requests both with and without OTel
telemetry enabled. Telemetry is opt-in via OTEL_EXPORTER_OTLP_ENDPOINT and
must never be a hard dependency for the app to run — see ite_api/telemetry.py.
"""

from collections.abc import Iterator

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from ite_api.telemetry import setup_telemetry


def _make_client(monkeypatch, postgres_url: str, tmp_path) -> TestClient:
    monkeypatch.setenv("ITE_DATABASE_URL", postgres_url)
    monkeypatch.setenv("ITE_JWT_SECRET", "test-secret-32-bytes-of-test-data!")
    monkeypatch.setenv("ITE_ALLOWED_ORIGINS", "http://localhost")
    monkeypatch.setenv("ITE_DATA_DIR", str(tmp_path / "data"))
    from ite_api.main import create_app

    app = create_app()
    c = TestClient(app)
    c.headers["Origin"] = "http://localhost"
    return c


@pytest.fixture()
def _clean_otel_env(monkeypatch) -> Iterator[None]:
    monkeypatch.delenv("OTEL_EXPORTER_OTLP_ENDPOINT", raising=False)
    monkeypatch.delenv("OTEL_EXPORTER_OTLP_HEADERS", raising=False)
    yield


def test_app_starts_and_serves_with_telemetry_disabled(
    monkeypatch, postgres_url: str, engine, tmp_path, _clean_otel_env
) -> None:
    """No OTEL_EXPORTER_OTLP_ENDPOINT set — the default, and every real
    deployment today — must behave exactly like before this feature existed.
    """
    client = _make_client(monkeypatch, postgres_url, tmp_path)
    with client:
        resp = client.get("/api/health")
        assert resp.status_code == 200
        assert resp.json()["status"] == "ok"


def test_app_starts_and_serves_with_telemetry_enabled(
    monkeypatch, postgres_url: str, engine, tmp_path
) -> None:
    """OTEL_EXPORTER_OTLP_ENDPOINT set to a closed local port: export attempts
    fail fast in the background (connection refused) but must never affect
    the app's own request handling.
    """
    monkeypatch.setenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:59999")
    monkeypatch.setenv("OTEL_EXPORTER_OTLP_HEADERS", "x-api-key=test-key")
    client = _make_client(monkeypatch, postgres_url, tmp_path)
    with client:
        resp = client.get("/api/health")
        assert resp.status_code == 200
        assert resp.json()["status"] == "ok"


def test_setup_telemetry_is_a_noop_without_endpoint(_clean_otel_env) -> None:
    """setup_telemetry must not raise, and must not require a DB/engine,
    when telemetry is disabled."""
    app = FastAPI()
    setup_telemetry(app)  # should return quietly, no instrumentation applied


def test_setup_telemetry_never_raises_with_endpoint_set(monkeypatch, db_session: Session) -> None:
    """Even with a (fake, unreachable) endpoint configured, instrumenting a
    fresh FastAPI app must not raise."""
    monkeypatch.setenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:59999")
    monkeypatch.setenv("OTEL_EXPORTER_OTLP_HEADERS", "x-api-key=test-key")
    app = FastAPI()
    setup_telemetry(app)
