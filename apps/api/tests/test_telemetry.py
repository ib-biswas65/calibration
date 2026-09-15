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


def test_setup_telemetry_is_a_noop_without_endpoint(monkeypatch, _clean_otel_env) -> None:
    """setup_telemetry must not raise, must not require a DB/engine, and —
    per this module's own contract — must construct zero SDK objects when
    telemetry is disabled.

    "Doesn't raise" alone is a weak proof: a call that's skipped entirely
    can't raise either. So we prove the stronger claim directly: patch
    TracerProvider.__init__ to blow up (and record) if it's ever invoked,
    reset the module's cache so no earlier test can mask a real call, then
    confirm neither the constructor fired nor the cache got populated.
    """
    from opentelemetry.sdk.trace import TracerProvider

    import ite_api.telemetry as telemetry_module

    constructed: list[bool] = []

    def _fail_if_constructed(self, *args, **kwargs):
        constructed.append(True)
        raise AssertionError("TracerProvider must not be constructed when telemetry is disabled")

    monkeypatch.setattr(TracerProvider, "__init__", _fail_if_constructed)
    monkeypatch.setattr(telemetry_module, "_tracer_provider", None)

    app = FastAPI()
    setup_telemetry(app)  # should return quietly, no instrumentation applied

    assert constructed == [], "TracerProvider was constructed even though telemetry is disabled"
    assert telemetry_module._tracer_provider is None


def test_setup_telemetry_never_raises_with_endpoint_set(monkeypatch, db_session: Session) -> None:
    """Even with a (fake, unreachable) endpoint configured, instrumenting a
    fresh FastAPI app must not raise."""
    monkeypatch.setenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:59999")
    monkeypatch.setenv("OTEL_EXPORTER_OTLP_HEADERS", "x-api-key=test-key")
    app = FastAPI()
    setup_telemetry(app)


def test_setup_telemetry_instruments_each_distinct_engine(monkeypatch) -> None:
    """A second create_app() in the same process against a *different*
    SQLAlchemy engine must still trigger this app's own instrumentation
    call for that engine, instead of being silently skipped by our
    bookkeeping.

    The "already instrumented" cache used to be a single module-level bool,
    so a second, different engine created later in the same process would
    be silently skipped once the first engine had flipped the flag. It's
    now keyed by engine identity — this is a regression test for that.

    What this test does NOT prove: with SQLAlchemyInstrumentor.instrument
    mocked out here, this only demonstrates that *this app's* WeakSet
    bookkeeping calls .instrument() once per distinct engine. It cannot
    demonstrate that a second real engine is actually instrumented by the
    real library in production, because the mock does not reproduce
    opentelemetry-instrumentation-sqlalchemy's own process-wide singleton
    guard (BaseInstrumentor only ever completes the first .instrument()
    call in a process; a real second call is a silent no-op at the library
    level). See the _instrumented_engines comment in ite_api/telemetry.py
    for the full explanation. This has no effect on Calibration's actual
    single-engine-per-process deployment.
    """
    from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
    from sqlalchemy import create_engine

    import ite_api.telemetry as telemetry_module
    from ite_api.db import session as db_session_module

    monkeypatch.setenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:59999")
    monkeypatch.setenv("OTEL_EXPORTER_OTLP_HEADERS", "x-api-key=test-key")
    monkeypatch.setattr(telemetry_module, "_tracer_provider", None)
    monkeypatch.setattr(db_session_module, "_init", lambda: None)

    instrumented_engines: list[object] = []

    def _fake_instrument(self, *, engine, tracer_provider=None):
        instrumented_engines.append(engine)

    monkeypatch.setattr(SQLAlchemyInstrumentor, "instrument", _fake_instrument)

    engine_a = create_engine("sqlite://")
    engine_b = create_engine("sqlite://")

    monkeypatch.setattr(db_session_module, "_engine", engine_a)
    setup_telemetry(FastAPI())

    monkeypatch.setattr(db_session_module, "_engine", engine_b)
    setup_telemetry(FastAPI())

    assert instrumented_engines == [engine_a, engine_b]

    # Calling again with the same (second) engine must not instrument it twice.
    setup_telemetry(FastAPI())
    assert instrumented_engines == [engine_a, engine_b]
