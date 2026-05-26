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
