t · PY
"""
wallet.py  ->  put this file in throb_backend/ (next to main.py).

Matches your current models:
  User.balance (Float), User.is_admin (Boolean)
  Transaction: type, amount (signed), status (pending|completed|rejected),
               method, reference, destination, description, admin_note,
               position_id (unique), created_at, processed_at

In main.py add:
    from wallet import router as wallet_router
    app.include_router(wallet_router)
"""
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import update
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from models import Position, Transaction, User

router = APIRouter()


# ---------- helpers ----------

def money(x: float) -> float:
    return round(float(x), 2)


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin only")
    return user


class DepositIn(BaseModel):
    amount: float = Field(gt=0)
    method: Optional[str] = None
    reference: Optional[str] = None      # deposit proof / txid


class WithdrawIn(BaseModel):
    amount: float = Field(gt=0)
    method: Optional[str] = None
    destination: Optional[str] = None    # withdrawal address or account


class ReviewIn(BaseModel):
    admin_note: Optional[str] = None


def tx_out(t: Transaction) -> dict:
    return {
        "id": t.id,
        "type": t.type,
        "amount": money(t.amount),       # signed: + adds, - removes
        "status": t.status,
        "method": t.method,
        "reference": t.reference,
        "destination": t.destination,
        "description": t.description,
        "admin_note": t.admin_note,
        "created_at": t.created_at.isoformat() if t.created_at else None,
        "processed_at": t.processed_at.isoformat() if t.processed_at else None,
    }


# ---------- user endpoints ----------

@router.get("/balance")
def get_balance(user: User = Depends(get_current_user)):
    """Home page."""
    return {"balance": money(user.balance)}


@router.post("/deposits")
def create_deposit(
    body: DepositIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deposit page: records the deposit as pending.
    The balance only increases when an admin completes it."""
    t = Transaction(
        user_id=user.id,
        type="deposit",
        amount=money(body.amount),
        status="pending",
        method=body.method,
        reference=body.reference,
    )
    db.add(t)
    db.commit()
    db.refresh(t)
    return tx_out(t)


@router.post("/withdrawals")
def create_withdrawal(
    body: WithdrawIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Withdrawal page: verifies funds, holds the money, waits for admin."""
    amt = money(body.amount)

    # Atomic check-and-deduct: only succeeds if the balance is big enough,
    # so two simultaneous requests can't spend the same money twice.
    result = db.execute(
        update(User)
        .where(User.id == user.id, User.balance >= amt)
        .values(balance=User.balance - amt)
    )
    if result.rowcount == 0:
        db.rollback()
        raise HTTPException(status_code=400, detail="Insufficient funds")

    t = Transaction(
        user_id=user.id,
        type="withdrawal",
        amount=-amt,                      # negative: money leaving
        status="pending",
        method=body.method,
        destination=body.destination,
    )
    db.add(t)
    db.commit()
    db.refresh(t)
    return tx_out(t)


@router.get("/transactions")
def list_transactions(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """History page."""
    rows = (
        db.query(Transaction)
        .filter(Transaction.user_id == user.id)
        .order_by(Transaction.created_at.desc())
        .all()
    )
    return [tx_out(t) for t in rows]


# ---------- admin endpoints ----------

@router.get("/admin/transactions")
def admin_list(
    status: str = "pending",
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(Transaction)
        .filter(Transaction.status == status)
        .order_by(Transaction.created_at.asc())
        .all()
    )
    return [{**tx_out(t), "user_id": t.user_id} for t in rows]


def _get_pending(db: Session, tx_id: int) -> Transaction:
    t = db.get(Transaction, tx_id)
    if not t:
        raise HTTPException(status_code=404, detail="Transaction not found")
    if t.status != "pending":
        raise HTTPException(status_code=409, detail="Already reviewed")
    if t.type not in ("deposit", "withdrawal"):
        raise HTTPException(status_code=400, detail="Not reviewable")
    return t


@router.post("/admin/transactions/{tx_id}/approve")
def approve(
    tx_id: int,
    body: ReviewIn = ReviewIn(),
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    t = _get_pending(db, tx_id)

    if t.type == "deposit":
        # Money arrives: credit the balance now.
        db.execute(
            update(User)
            .where(User.id == t.user_id)
            .values(balance=User.balance + abs(t.amount))
        )
    # Withdrawal: money was already held when requested, nothing to change.
    # (This is where you'd trigger the real payout.)

    t.status = "completed"
    t.admin_note = body.admin_note
    t.processed_at = datetime.utcnow()
    db.commit()
    return tx_out(t)


@router.post("/admin/transactions/{tx_id}/reject")
def reject(
    tx_id: int,
    body: ReviewIn = ReviewIn(),
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    t = _get_pending(db, tx_id)

    if t.type == "withdrawal":
        # Give the held money back.
        db.execute(
            update(User)
            .where(User.id == t.user_id)
            .values(balance=User.balance + abs(t.amount))
        )

    t.status = "rejected"
    t.admin_note = body.admin_note
    t.processed_at = datetime.utcnow()
    db.commit()
    return tx_out(t)


# ---------- trading P/L ----------

def settle_position(db: Session, position: Position) -> float:
    """Call when a position is closed (after close_price / closed_at are set).
    Works out profit or loss, updates the balance, and logs it in history.
    Returns the P/L (negative = loss).

    Transaction.position_id is unique, so a trade can only be settled once."""
    already = (
        db.query(Transaction).filter(Transaction.position_id == position.id).first()
    )
    if already:
        raise ValueError("Position already settled")

    move = (position.close_price - position.entry_price) / position.entry_price
    if position.side.lower() in ("sell", "short"):
        move = -move
    pnl = money(position.amount_usd * move)

    db.execute(
        update(User)
        .where(User.id == position.user_id)
        .values(balance=User.balance + pnl)
    )
    db.add(
        Transaction(
            user_id=position.user_id,
            type="profit" if pnl >= 0 else "loss",
            amount=pnl,                   # signed
            status="completed",
            position_id=position.id,
            description=f"{position.symbol} {position.side}",
            processed_at=datetime.utcnow(),
        )
    )
    db.commit()
    return pnl
