"""OpenTelemetry wiring for HTTP + SQLAlchemy tracing.

LOCAL DEVELOPMENT ONLY, for now. The only place a monoscope (self-hosted
OpenTelemetry backend) instance exists is ``http://localhost:8080`` on a
developer's own Mac. This API's production deployment target is a Windows
lab PC with no network path to that Mac, so telemetry only ever flows when
someone runs this API locally for testing — never from the real production
deployment. There is no tunnel/VPN wiring for that gap yet; if that changes,
revisit this module.

Enabling telemetry is entirely opt-in and driven by the standard OpenTelemetry
SDK environment variables, which the SDK/exporter read on their own:

  - ``OTEL_EXPORTER_OTLP_ENDPOINT`` — e.g. ``http://localhost:8080``.
  - ``OTEL_EXPORTER_OTLP_HEADERS`` — e.g. ``x-api-key=<project-api-key>``.
    monoscope requires the ``x-api-key`` header specifically; an
    ``Authorization: Bearer`` header is accepted with HTTP 200 but the data
    is silently dropped.

If ``OTEL_EXPORTER_OTLP_ENDPOINT`` is unset (the default), ``setup_telemetry``
does nothing at all — no SDK objects are constructed, no instrumentation is
applied, zero added overhead. Any failure while setting up telemetry (bad
endpoint value, an optional dependency missing, etc.) is caught and logged;
telemetry must never break the app or block startup.
"""

from __future__ import annotations

import logging
import os
import weakref

from fastapi import FastAPI

_log = logging.getLogger(__name__)

SERVICE_NAME = "calibration-api"

# Module-level cache so repeated calls (e.g. create_app() invoked multiple
# times in the same process, as the test suite does) reuse one TracerProvider
# and avoid asking this app's own code to re-instrument an engine it has
# already seen, instead of piling up duplicate exporters/background export
# threads or issuing a redundant .instrument() call for the same engine.
#
# _instrumented_engines is keyed by engine identity (a WeakSet of the engine
# objects themselves, not a plain bool) so that if create_app() ever runs
# more than once in the same process with *different* engine instances
# (e.g. the test suite), this app's own bookkeeping does not skip the
# second engine just because "some engine, once upon a time" was already
# seen.
#
# IMPORTANT LIMITATION (outside this app's control): this WeakSet only
# prevents *this app* from calling .instrument() twice on the same engine.
# It does not make more than one engine per process actually get
# instrumented in production. opentelemetry-instrumentation-sqlalchemy's
# SQLAlchemyInstrumentor extends BaseInstrumentor, which is a class-level
# singleton (its __new__ always returns the same instance) and tracks
# "already instrumented" as a class-level flag set on the FIRST successful
# .instrument() call anywhere in the process. That flag is never reset per
# engine, so a genuinely second .instrument(engine=engine_b, ...) call later
# in the same process is silently a no-op at the library level, even though
# engine_b is not in _instrumented_engines and this app dutifully calls
# .instrument() for it. This is a known, permanent characteristic of how
# most OTel Python instrumentors are designed (one instrumentation per
# process), not a bug to keep chasing here. It has no practical effect
# today: Calibration's real deployment is one process, one engine, one
# create_app() call. If this app ever legitimately needs more than one
# SQLAlchemy engine instrumented in the same process, this approach will
# not achieve that — a different strategy would be needed (e.g. check
# whether the library exposes a way to hook a specific engine directly via
# SQLAlchemy's own event system, rather than going through
# SQLAlchemyInstrumentor's process-wide singleton).
_tracer_provider = None
_instrumented_engines: weakref.WeakSet = weakref.WeakSet()


def setup_telemetry(app: FastAPI) -> None:
    """Instrument ``app`` (FastAPI + its SQLAlchemy engine) if telemetry is enabled.

    Safe to call unconditionally from ``create_app()``: it is a no-op unless
    ``OTEL_EXPORTER_OTLP_ENDPOINT`` is set, and never raises.
    """
    global _tracer_provider

    endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "").strip()
    if not endpoint:
        _log.info(
            "OTEL_EXPORTER_OTLP_ENDPOINT not set; OpenTelemetry tracing disabled "
            "(expected in production — see ite_api/telemetry.py)."
        )
        return

    try:
        from opentelemetry import trace
        from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
        from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
        from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor

        if _tracer_provider is None:
            resource = Resource.create({"service.name": SERVICE_NAME})
            provider = TracerProvider(resource=resource)
            # No endpoint/headers args: OTLPSpanExporter reads
            # OTEL_EXPORTER_OTLP_ENDPOINT (appending /v1/traces itself) and
            # OTEL_EXPORTER_OTLP_HEADERS natively — no custom env parsing needed.
            provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
            trace.set_tracer_provider(provider)
            _tracer_provider = provider

        FastAPIInstrumentor.instrument_app(app, tracer_provider=_tracer_provider)

        from ite_api.db import session as db_session

        db_session._init()
        engine = db_session._engine
        if engine not in _instrumented_engines:
            # This only stops *this app* from redundantly calling
            # .instrument() on an engine it has already seen. It does not
            # guarantee a second, genuinely different engine gets
            # instrumented by the library — see the module-level comment
            # on _instrumented_engines above for why.
            SQLAlchemyInstrumentor().instrument(
                engine=engine, tracer_provider=_tracer_provider
            )
            _instrumented_engines.add(engine)

        _log.info(
            "OpenTelemetry tracing enabled: service=%s endpoint=%s", SERVICE_NAME, endpoint
        )
    except Exception:
        _log.exception(
            "Failed to set up OpenTelemetry tracing; continuing without it."
        )
