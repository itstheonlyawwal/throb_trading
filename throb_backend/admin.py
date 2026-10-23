
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from deps import get_db, require_admin
from models import User, Position


router = APIRouter(prefix="/admin", tags=["admin"])


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