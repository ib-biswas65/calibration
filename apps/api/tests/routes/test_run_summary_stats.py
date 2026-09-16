"""list_runs' aggregation stats for the new "partial" status / "invalid" verdict.

Calls the route function directly against a real Postgres (db_session) rather than
through the HTTP layer/TestClient — see the handoff notes on why the `client`
fixture can't be combined with `db_session` in the same test session right now
(pre-existing conftest/alembic collision, out of scope for this change).
"""

from ite_api.db.models.calibration import CalibrationRun, LoggerResult
from ite_api.routes.runs import list_runs


def _make_run(db_session, **overrides):
    defaults = dict(
        batch_name="Stats Test",
        status="partial",
        testing_start="2026-04-14T09:00:00+00:00",
        testing_end="2026-04-14T10:00:00+00:00",
        certificate_date="2026-04-15",
        threshold_c=0.5,
        setpoints=[],
        start_cert_no="0000009100",
        cert_width=10,
        test_date_jp="2026年4月14日",
        doc_date_jp="2026年4月15日",
    )
    defaults.update(overrides)
    run = CalibrationRun(**defaults)
    db_session.add(run)
    db_session.commit()
    db_session.refresh(run)
    return run


def test_partial_run_pass_rate_excludes_invalid_from_denominator(db_session):
    run = _make_run(db_session)
    db_session.add_all(
        [
            LoggerResult(
                run_id=run.id, sheet_name="A", verdict="pass", max_deviation_c=0.1, per_setpoint=[]
            ),
            LoggerResult(
                run_id=run.id, sheet_name="B", verdict="fail", max_deviation_c=0.8, per_setpoint=[]
            ),
            LoggerResult(
                run_id=run.id,
                sheet_name="C",
                verdict="invalid",
                max_deviation_c=None,
                per_setpoint=[],
                failure_reason="no match",
            ),
        ]
    )
    db_session.commit()

    rows = list_runs(
        status_filter=None,
        from_date=None,
        to_date=None,
        q=None,
        limit=50,
        db=db_session,
        user=None,
    )
    row = next(r for r in rows if r.id == run.id)

    assert row.status == "partial"
    # 1 pass out of 2 *valid* results (invalid excluded from the denominator) = 50%.
    assert row.pass_rate == 50.0
    assert row.logger_count == 3
    assert row.max_deviation_c == 0.8
