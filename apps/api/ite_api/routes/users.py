"""Admin user management — list, invite (password reset link), change role, disable."""

import uuid
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import select
from sqlalchemy.orm import Session

from ite_api.audit import write_audit
from ite_api.auth.dependencies import require_role
from ite_api.auth.passwords import hash_password
from ite_api.auth.tokens import create_refresh_token, hash_refresh_token
from ite_api.db.models import PasswordReset, User
from ite_api.db.session import get_session

router = APIRouter(prefix="/api/auth/users", tags=["users"])


class UserOut(BaseModel):
    id: str
    email: str
    full_name: str
    role: str
    disabled: bool
    pending: bool
    created_at: datetime
    last_login_at: datetime | None


class CreateUserRequest(BaseModel):
    email: EmailStr
    full_name: str
    role: str = "engineer"


class PatchUserRequest(BaseModel):
    role: str | None = None
    disabled: bool | None = None


@router.get("", response_model=list[UserOut])
def list_users(
    db: Session = Depends(get_session),
    admin: User = require_role("admin"),
):
    users = db.scalars(select(User).order_by(User.created_at)).all()
    return [UserOut(
        id=str(u.id), email=u.email, full_name=u.full_name,
        role=u.role, disabled=u.disabled, pending=u.pending,
        created_at=u.created_at, last_login_at=u.last_login_at,
    ) for u in users]


@router.get("/pending", response_model=list[UserOut])
def list_pending_users(
    db: Session = Depends(get_session),
    admin: User = require_role("admin"),
):
    """Return only users awaiting approval."""
    users = db.scalars(select(User).where(User.pending == True).order_by(User.created_at)).all()  # noqa: E712
    return [UserOut(
        id=str(u.id), email=u.email, full_name=u.full_name,
        role=u.role, disabled=u.disabled, pending=u.pending,
        created_at=u.created_at, last_login_at=u.last_login_at,
    ) for u in users]


@router.post("", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_user(
    body: CreateUserRequest,
    db: Session = Depends(get_session),
    admin: User = require_role("admin"),
):
    if body.role not in ("admin", "engineer", "viewer"):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, detail="invalid role")
    if db.scalars(select(User).where(User.email == body.email.lower())).first():
        raise HTTPException(status.HTTP_409_CONFLICT, detail="email already registered")

    # Create user with a placeholder password; they must use the setup link
    user = User(
        email=body.email.lower(),
        full_name=body.full_name,
        role=body.role,
        password_hash=hash_password(create_refresh_token()),  # random strong hash
    )
    db.add(user)
    db.flush()

    # Create a 7-day password-reset (setup) token
    raw_token = create_refresh_token()
    expires = datetime.now(UTC) + timedelta(days=7)
    pr = PasswordReset(
        user_id=user.id,
        token_hash=hash_refresh_token(raw_token),
        expires_at=expires,
    )
    db.add(pr)
    db.commit()
    write_audit(db, user_id=admin.id, action="user.created", detail={"new_user_id": str(user.id)})

    # In v1 (no SMTP) return the setup link for the admin to share manually
    setup_url = f"/reset-password?token={raw_token}"
    return {"user_id": str(user.id), "setup_url": setup_url}


@router.post("/{user_id}/approve", status_code=status.HTTP_204_NO_CONTENT)
def approve_user(
    user_id: uuid.UUID,
    db: Session = Depends(get_session),
    admin: User = require_role("admin"),
):
    """Approve a self-registered pending user — they can now log in immediately."""
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="user not found")
    if not user.pending:
        raise HTTPException(status.HTTP_409_CONFLICT, detail="user is not pending approval")

    user.pending = False
    db.commit()
    write_audit(db, user_id=admin.id, action="user.approved", detail={"target_user_id": str(user_id)})


@router.post("/{user_id}/reject", status_code=status.HTTP_204_NO_CONTENT)
def reject_user(
    user_id: uuid.UUID,
    db: Session = Depends(get_session),
    admin: User = require_role("admin"),
):
    """Reject and permanently delete a pending registration request."""
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="user not found")
    if not user.pending:
        raise HTTPException(status.HTTP_409_CONFLICT, detail="user is not pending approval")

    write_audit(db, user_id=admin.id, action="user.rejected", detail={"email": user.email})
    db.delete(user)
    db.commit()


@router.post("/{user_id}/invite", response_model=dict)
def resend_invite(
    user_id: uuid.UUID,
    db: Session = Depends(get_session),
    admin: User = require_role("admin"),
):
    """Generate a fresh 7-day setup link for a user who has not yet logged in."""
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="user not found")
    if user.disabled:
        raise HTTPException(status.HTTP_409_CONFLICT, detail="user is disabled")
    if user.last_login_at is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, detail="user has already logged in — use password reset instead")

    raw_token = create_refresh_token()
    expires = datetime.now(UTC) + timedelta(days=7)
    db.add(PasswordReset(
        user_id=user.id,
        token_hash=hash_refresh_token(raw_token),
        expires_at=expires,
    ))
    db.commit()
    write_audit(db, user_id=admin.id, action="user.invite_resent", detail={"target_user_id": str(user_id)})

    setup_url = f"/reset-password?token={raw_token}"
    return {"setup_url": setup_url}


@router.patch("/{user_id}", response_model=UserOut)
def patch_user(
    user_id: uuid.UUID,
    body: PatchUserRequest,
    db: Session = Depends(get_session),
    admin: User = require_role("admin"),
):
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="user not found")
    if body.role is not None:
        if body.role not in ("admin", "engineer", "viewer"):
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, detail="invalid role")
        user.role = body.role
        write_audit(db, user_id=admin.id, action="user.role_changed",
                    detail={"target_user_id": str(user_id), "new_role": body.role})
    if body.disabled is not None:
        user.disabled = body.disabled
    db.commit()
    db.refresh(user)
    return UserOut(
        id=str(user.id), email=user.email, full_name=user.full_name,
        role=user.role, disabled=user.disabled, pending=user.pending,
        created_at=user.created_at, last_login_at=user.last_login_at,
    )
