from datetime import datetime
from pathlib import Path

import typer

from ite_api.auth.passwords import hash_password
from ite_api.db import session as db_session_mod
from ite_api.db.models import User

app = typer.Typer(help="ITE Calibration API CLI")


# Forces Typer into multi-command mode so `ite-api create-admin ...` works.
@app.command("version", hidden=True)
def _version() -> None:
    typer.echo("ite-api 0.1.0")


@app.command("create-admin")
def create_admin(
    email: str = typer.Option(..., "--email"),
    full_name: str = typer.Option(..., "--full-name"),
    password: str = typer.Option(..., "--password", help="min 12 chars"),
) -> None:
    if len(password) < 12:
        raise typer.BadParameter("password must be at least 12 characters")
    db_session_mod._init()
    SessionLocal = db_session_mod._SessionLocal
    assert SessionLocal is not None
    with SessionLocal() as db:
        if db.query(User).filter_by(email=email.lower()).first():
            raise typer.BadParameter(f"user {email} already exists")
        db.add(User(
            email=email.lower(),
            full_name=full_name,
            password_hash=hash_password(password),
            role="admin",
        ))
        db.commit()
    typer.echo(f"Created admin {email}")


@app.command("run-calibration")
def run_calibration_cmd(
    workbook: Path = typer.Option(..., "--workbook", exists=True, dir_okay=False),
    reference: list[Path] = typer.Option(..., "--reference", exists=True, dir_okay=False),
    template: Path = typer.Option(..., "--template", exists=True, dir_okay=False),
    output: Path = typer.Option(..., "--output", file_okay=False),
    start_cert_no: str = typer.Option("0000001000", "--start-cert-no"),
    cert_width: int = typer.Option(10, "--cert-width"),
    test_date_jp: str = typer.Option(..., "--test-date-jp"),
    doc_date_jp: str = typer.Option(..., "--doc-date-jp"),
    window_start: datetime = typer.Option(
        datetime(1900, 1, 1, 0, 0), "--window-start",
        help="Start of testing window (defaults to a very early date).",
    ),
    window_end: datetime = typer.Option(
        datetime(2999, 12, 31, 23, 59), "--window-end",
        help="End of testing window (defaults to a very late date).",
    ),
) -> None:
    """Generate calibration certificates from a workbook and reference CSV(s)."""
    from ite_api.calibration.engine import BatchConfig, SetpointWindow, run_calibration

    setpoints = [
        SetpointWindow(target=t, start=window_start, end=window_end)
        for t in (-40.0, 5.0, 40.0)
    ]
    cfg = BatchConfig(
        start_cert_no=start_cert_no,
        cert_width=cert_width,
        test_date_jp=test_date_jp,
        doc_date_jp=doc_date_jp,
        template_path=template,
        calibration_xlsx=workbook,
        reference_csvs=list(reference),
        output_dir=output,
        setpoints=setpoints,
    )
    written = run_calibration(cfg)
    for p in written:
        typer.echo(str(p))
    typer.echo(f"Wrote {len(written)} certificate(s) to {output}")
