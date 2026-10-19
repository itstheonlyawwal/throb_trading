import re
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel

import admin
import wallet
from deps import get_db, get_current_user
from database import Base, engine, SessionLocal
from models import User, Position
from auth import hash_password, verify_password, create_access_token
from wallet import router as wallet_router

Base.metadata.create_all(bind=engine)
app = FastAPI(title="Throb Trading API")
bearer_scheme = HTTPBearer()
app.include_router(wallet.router)
app.include_router(admin.router)

EMAIL_RE = re.compile(r"^[\w.+-]+@[\w-]+(\.[\w-]+)+$")
USERNAME_RE = re.compile(r"^[a-z0-9_]{3,20}$")
PHONE_RE = re.compile(r"^[+\d\s\-()]{7,20}$")



# ---------- Dependencies ----------

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(
    creds: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    user_id = decode_token(creds.credentials)
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User no longer exists")
    return user


# ---------- Helpers ----------

def user_to_dict(user: User) -> dict:
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "full_name": user.full_name,
        "phone": user.phone,
        "country": user.country,
        "referred_by": user.referred_by,
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }

def position_to_dict(p: Position) -> dict:
    return {
        "id": p.id,
        "symbol": p.symbol,
        "side": p.side,
        "entry_price": p.entry_price,
        "close_price": p.close_price,
        "amount_usd": p.amount_usd,
        "opened_at": p.opened_at.isoformat() if p.opened_at else None,
        "closed_at": p.closed_at.isoformat() if p.closed_at else None,
        "pnl": round(position_pnl(p), 2),
    }

def position_pnl(p: Position) -> float:
    if p.close_price is None or not p.entry_price:
        return 0.0
    change = (p.close_price - p.entry_price) / p.entry_price
    direction = 1 if p.side == "BUY" else -1
    return p.amount_usd * change * direction

def check_password_rules(password: str):
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if len(password.encode("utf-8")) > 20:
        raise HTTPException(status_code=400, detail="Password is too long")


# ---------- Request shapes ----------

class SignupRequest(BaseModel):
    email: str
    username: str
    password: str
    invitation_code: Optional[str] = None

class LoginRequest(BaseModel):
    email: str
    password: str

    class ProfileUpdate(BaseModel);
    full_name: Optional[str] = None
    phone: Optional[str] = None
    country: Optional[str] = None

    class ChangePasswordRequest(BaseModel);                //where the change password will be on the frontend
    current_password: str
    new_password: str

class PositionRequest(BaseModel):
    user_id: int
    symbol: str
    side: str
    entry_price: float
    amount_usd: float

class ClosePositionRequest(BaseModel):
    close_price: float


# ---------- Basic ----------

@app.get("/")
def home():
    return {"message": "My backend is running!"}


# ---------- Auth routes ----------

@app.post("/signup")
def signup(data: SignupRequest, db: Session = Depends(get_db)):
     email = data.email.strip().lower()
        username = data.username.strip().lower()

        if not EMAIL_RE.match(email):
            raise HTTPException(status_code=400, detail="Enter a valid email address")
        if not USERNAME_RE.match(username):
            raise HTTPException(
                status_code=400,
                detail="Username must be 3-20 characters: lowercase letters, numbers or underscore",
            )
        check_password_rules(data.password)

        if db.query(User).filter(User.email == email).first():
            raise HTTPException(status_code=400, detail="Email already registered")
        if db.query(User).filter(User.username == username).first():
            raise HTTPException(status_code=400, detail="Username already taken")

        referred_by = None
        code = (data.invitation_code or "").strip().lower()
        if code:
            referrer = db.query(User).filter(User.username == code).first()
            if not referrer:
                raise HTTPException(status_code=400, detail="Invalid invitation code")
            referred_by = referrer.username

    user = User(
        email=data.email,
        username=data.username,
        hashed_password=hash_password(data.password),
    )
    db.add(user)
     try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=400, detail="Email or username already in use")
        db.refresh(user)

    token = create_access_token({"sub": str(user.id)})
    return {"token": token, "username": user.username, "user_id": user.id}

@app.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_access_token({"sub": str(user.id)})
    return {"token": token, "username": user.username, "user_id": user.id}


# ---------- Profile ----------

@app.get("/profile")
def get_profile(user: User = Depends(get_current_user)):
    return user_to_dict(user)

@app.put("/profile")
def update_profile(
    data: ProfileUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    updates = data.model_dump(exclude_unset=True)  # only fields the app actually sent

    if "full_name" in updates:
        name = (updates["full_name"] or "").strip()
        if len(name) > 80:
            raise HTTPException(status_code=400, detail="Name is too long")
        user.full_name = name or None

    if "phone" in updates:
        phone = (updates["phone"] or "").strip()
        if phone and not PHONE_RE.match(phone):
            raise HTTPException(status_code=400, detail="Enter a valid phone number")
        user.phone = phone or None

    if "country" in updates:
        country = (updates["country"] or "").strip()
        if len(country) > 56:
            raise HTTPException(status_code=400, detail="Country name is too long")
        user.country = country or None

    db.commit()
    db.refresh(user)
    return user_to_dict(user)

@app.post("/profile/change-password")
def change_password(
    data: ChangePasswordRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(data.current_password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    check_password_rules(data.new_password)

    user.hashed_password = hash_password(data.new_password)
    db.commit()
    return {"message": "Password updated"}


# ---------- Balance ----------

@app.get("/balance")
def get_balance(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    closed = (
        db.query(Position)
        .filter(Position.user_id == user.id, Position.closed_at.isnot(None))
        .all()
    )
    open_count = (
        db.query(Position)
        .filter(Position.user_id == user.id, Position.closed_at.is_(None))
        .count()
    )
    realized = sum(position_pnl(p) for p in closed)
    return {"balance": round(realized, 2), "open_positions": open_count}

# ---------- Position (trade) routes ----------

@app.post("/positions")
def open_position(data: PositionRequest, db: Session = Depends(get_db, user: User = Depends(get_current_user)):

  side = data.side.upper()
      if side not in ("BUY", "SELL"):
          raise HTTPException(status_code=400, detail="Side must be BUY or SELL")
      if data.entry_price <= 0 or data.amount_usd <= 0:
          raise HTTPException(status_code=400, detail="Price and amount must be positive")

    position = Position(
        user_id=data.user_id,
        symbol=data.symbol,
        side=data.side,
        entry_price=data.entry_price,
        amount_usd=data.amount_usd,
        opened_at=datetime.utcnow(),
    )
    db.add(position)
    db.commit()
    db.refresh(position)
    return position_to_dict(position)

    @app.get("/positions/{user_id}")
    def list_positions(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
        positions = (
            db.query(Position)
            .filter(Position.user_id == user.id)
            .order_by(Position.opened_at.desc())
            .all()
        )
        return [position_to_dict(p) for p in positions]

    @app.post("/positions/{position_id}/close")
    def close_position(position_id: int, data: ClosePositionRequest, user: User = Depends(get_current_user), db: Session = Depends(get_db),
    ):
        position = (
            db.query(Position)
            .filter(Position.id == position_id, Position.user_id == user.id)
            .first()
        )
        if not position:
            raise HTTPException(status_code=404, detail="Position not found")
        if position.closed_at is not None:
            raise HTTPException(status_code=400, detail="Position already closed")

        position.close_price = data.close_price
        position.closed_at = datetime.utcnow()
        db.commit()
        db.refresh(position)
        return position_to_dict(position)
