from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Cookie, Depends, HTTPException, Response, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ite_api.audit import write_audit
from ite_api.auth.dependencies import current_user
from ite_api.auth.lockout import is_locked_out, record_failed_attempt
from ite_api.auth.passwords import hash_password, verify_password
from ite_api.auth.tokens import (
    create_access_token,
    create_refresh_token,
    hash_refresh_token,
)
from ite_api.config import get_settings
from ite_api.db.models import PasswordReset, User
from ite_api.db.models import Session as UserSession
from ite_api.db.session import get_session

router = APIRouter(prefix="/api/auth", tags=["auth"])


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class MeResponse(BaseModel):
    id: str
    email: str
    full_name: str
    role: str


def _set_auth_cookies(response: Response, *, access: str, refresh: str) -> None:
    s = get_settings()
    response.set_cookie(
        key=s.cookie_access_name,
        value=access,
        max_age=s.access_token_minutes * 60,
        httponly=True,
        secure=s.cookie_secure,
        samesite=s.cookie_samesite,
        path="/",
    )
    response.set_cookie(
        key=s.cookie_refresh_name,
        value=refresh,
        max_age=s.refresh_token_days * 24 * 60 * 60,
        httponly=True,
        secure=s.cookie_secure,
        samesite=s.cookie_samesite,
        path="/",
    )


@router.post("/login", status_code=status.HTTP_204_NO_CONTENT)
def login(
    payload: LoginRequest,
    response: Response,
    db: Session = Depends(get_session),
):
    email = payload.email.lower()

    if is_locked_out(db, email=email):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, detail="too many failed attempts")

    user = db.execute(select(User).where(func.lower(User.email) == email)).scalar_one_or_none()
    if user is None or user.disabled or not verify_password(payload.password, user.password_hash):
        record_failed_attempt(db, email=email)
        db.commit()
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="invalid credentials")

    s = get_settings()
    refresh = create_refresh_token()
    db.add(UserSession(
        user_id=user.id,
        token_hash=hash_refresh_token(refresh),
        expires_at=datetime.now(UTC) + timedelta(days=s.refresh_token_days),
    ))
    user.last_login_at = datetime.now(UTC)
    write_audit(db, user_id=user.id, action="login", detail={"email": email})
    db.commit()

    access = create_access_token(user_id=str(user.id), role=user.role)
    _set_auth_cookies(response, access=access, refresh=refresh)
    response.status_code = status.HTTP_204_NO_CONTENT
    return response


@router.get("/me", response_model=MeResponse)
def me(user: User = current_user) -> MeResponse:
    return MeResponse(
        id=str(user.id),
        email=user.email,
        full_name=user.full_name,
        role=user.role,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(
    db: Session = Depends(get_session),
    ite_rt: str | None = Cookie(default=None),
) -> Response:
    s = get_settings()
    if ite_rt:
        sess = (
            db.query(UserSession)
            .filter_by(token_hash=hash_refresh_token(ite_rt))
            .one_or_none()
        )
        if sess and sess.revoked_at is None:
            sess.revoked_at = datetime.now(UTC)
            write_audit(db, user_id=sess.user_id, action="logout", detail=None)
            db.commit()
    out = Response(status_code=status.HTTP_204_NO_CONTENT)
    out.delete_cookie(s.cookie_access_name, path="/")
    out.delete_cookie(s.cookie_refresh_name, path="/")
    return out


class ResetPasswordRequest(BaseModel):
    token: str
    password: str


@router.post("/reset-password", status_code=status.HTTP_204_NO_CONTENT)
def reset_password(
    body: ResetPasswordRequest,
    response: Response,
    db: Session = Depends(get_session),
) -> Response:
    if len(body.password) < 12:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, detail="password must be at least 12 characters")

    token_hash = hash_refresh_token(body.token)
    pr = db.scalars(select(PasswordReset).where(PasswordReset.token_hash == token_hash)).first()
    if pr is None or pr.used_at is not None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="invalid or already-used reset token")
    if pr.expires_at < datetime.now(UTC):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="reset token has expired")

    user = db.get(User, pr.user_id)
    if user is None or user.disabled:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="user not found or disabled")

    user.password_hash = hash_password(body.password)
    pr.used_at = datetime.now(UTC)
    write_audit(db, user_id=user.id, action="password.reset", detail=None)
    db.commit()

    s = get_settings()
    refresh = create_refresh_token()
    db.add(UserSession(
        user_id=user.id,
        token_hash=hash_refresh_token(refresh),
        expires_at=datetime.now(UTC) + timedelta(days=s.refresh_token_days),
    ))
    db.commit()

    access = create_access_token(user_id=str(user.id), role=user.role)
    _set_auth_cookies(response, access=access, refresh=refresh)
    response.status_code = status.HTTP_204_NO_CONTENT
    return response
