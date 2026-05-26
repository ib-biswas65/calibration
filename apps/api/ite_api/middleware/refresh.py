from datetime import datetime, timedelta, timezone

import jwt
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from ite_api.auth.tokens import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    hash_refresh_token,
)
from ite_api.config import get_settings
from ite_api.db.models import Session as UserSession
from ite_api.db.models import User
from ite_api.db import session as db_session_mod


class RefreshMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        s = get_settings()
        at = request.cookies.get(s.cookie_access_name)
        rt = request.cookies.get(s.cookie_refresh_name)
        rotated: tuple[str, str] | None = None

        if at:
            try:
                decode_access_token(at)
                return await call_next(request)
            except Exception:  # noqa: BLE001 — any decode failure → try refresh
                pass

        if rt is not None:
            rotated = self._rotate(rt)
            if rotated:
                new_at, new_rt = rotated
                cookie_value = (
                    f"{s.cookie_access_name}={new_at}; {s.cookie_refresh_name}={new_rt}"
                )
                hdrs = [(k, v) for k, v in request.scope["headers"] if k != b"cookie"]
                hdrs.append((b"cookie", cookie_value.encode()))
                request.scope["headers"] = hdrs

        response: Response = await call_next(request)

        if rotated:
            new_at, new_rt = rotated
            response.set_cookie(
                s.cookie_access_name, new_at,
                max_age=s.access_token_minutes * 60,
                httponly=True, secure=s.cookie_secure,
                samesite=s.cookie_samesite, path="/",
            )
            response.set_cookie(
                s.cookie_refresh_name, new_rt,
                max_age=s.refresh_token_days * 24 * 60 * 60,
                httponly=True, secure=s.cookie_secure,
                samesite=s.cookie_samesite, path="/",
            )
        return response

    def _rotate(self, presented_rt: str) -> tuple[str, str] | None:
        db_session_mod._init()
        SessionLocal = db_session_mod._SessionLocal
        assert SessionLocal is not None
        s = get_settings()
        token_hash = hash_refresh_token(presented_rt)
        with SessionLocal() as db:
            sess = db.query(UserSession).filter_by(token_hash=token_hash).one_or_none()
            now = datetime.now(timezone.utc)
            if sess is None or sess.revoked_at is not None or sess.expires_at < now:
                return None
            user = db.get(User, sess.user_id)
            if user is None or user.disabled:
                return None
            new_rt = create_refresh_token()
            sess.token_hash = hash_refresh_token(new_rt)
            sess.expires_at = now + timedelta(days=s.refresh_token_days)
            db.commit()
            new_at = create_access_token(user_id=str(user.id), role=user.role)
            return new_at, new_rt
