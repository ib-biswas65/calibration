"""last_30d.pass_rate must exclude invalid results from its denominator, same as
list_runs' pass_rate (see test_run_summary_stats.py) -- calls the route function
directly against db_session for the same reason documented there.
"""

from datetime import UTC, datetime

from ite_api.db.models.calibration import CalibrationRun, LoggerResult
from ite_api.routes.overview import get_overview


def _make_run(db_session, **overrides):
    defaults = dict(
        batch_name="Overview Stats Test",
        status="partial",
        testing_start="2026-04-14T09:00:00+00:00",
        testing_end="2026-04-14T10:00:00+00:00",
        certificate_date="2026-04-15",
        threshold_c=0.5,
        setpoints=[],
        start_cert_no="0000009200",
        cert_width=10,
        test_date_jp="2026年4月14日",
        doc_date_jp="2026年4月15日",
        created_at=datetime.now(UTC),
    )
    defaults.update(overrides)
    run = CalibrationRun(**defaults)
    db_session.add(run)
    db_session.commit()
    db_session.refresh(run)
    return run


def test_overview_pass_rate_excludes_invalid_from_denominator(db_session):
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

    resp = get_overview(db=db_session, user=None)

    # 1 pass out of 2 *valid* results — invalid excluded from the denominator.
    assert resp.last_30d.pass_rate == 50.0
