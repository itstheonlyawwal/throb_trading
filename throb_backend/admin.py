import os
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from deps import get_db, get_current_user
from models import User, Position

router = APIRouter(prefix="/admin", tags=["admin"])

ADMIN_EMAILS = {
    e.strip().lower()
    for e in os.getenv("ADMIN_EMAILS", "").split(",")
    if e.strip()
}


def require_admin(user: User = Depends(get_current_user)) -> User:
    if getattr(user, "is_admin", False) or user.email.lower() in ADMIN_EMAILS:
        return user
    raise HTTPException(status_code=403, detail="Admin only")


@router.get("/users")
def list_users(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return [
        {"id": u.id, "email": u.email, "username": u.username}
        for u in db.query(User).all()
    ]


@router.get("/positions")
def list_all_positions(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return [
        {
            "id": p.id,
            "user_id": p.user_id,
            "symbol": p.symbol,
            "side": p.side,
            "entry_price": p.entry_price,
            "amount_usd": p.amount_usd,
        }
        for p in db.query(Position).all()
    ]