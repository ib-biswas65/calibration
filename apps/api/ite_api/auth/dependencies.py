import uuid

from fastapi import Cookie, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ite_api.auth.tokens import decode_access_token
from ite_api.db.models import User
from ite_api.db.session import get_session

_ROLE_RANK = {"viewer": 1, "engineer": 2, "admin": 3}


def _current_user_impl(
    db: Session = Depends(get_session),
    ite_at: str | None = Cookie(default=None),
) -> User:
    if not ite_at:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="not authenticated")
    try:
        claims = decode_access_token(ite_at)
    except Exception as e:  # noqa: BLE001 — any JWT error → 401
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="invalid token") from e
    user = db.get(User, uuid.UUID(claims["sub"]))
    if user is None or user.disabled:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="user not found or disabled")
    return user


current_user = Depends(_current_user_impl)


def require_role(min_role: str):
    required = _ROLE_RANK[min_role]

    def _dep(user: User = Depends(_current_user_impl)) -> User:
        if _ROLE_RANK.get(user.role, 0) < required:
            raise HTTPException(status.HTTP_403_FORBIDDEN, detail="insufficient role")
        return user

    return Depends(_dep)
