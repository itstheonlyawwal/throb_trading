from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from database import Base

class User(Base):
    __tablename__= "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    country = Column(String, nullable=True)
    reffered_by = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class Position(Base):
    __tablename__ = "positions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    symbol = Column(String)
    side = Column(String)
    entry_price = Column(Float)
    close_price = Column(Float, nullable=True)
    amount_usd = Column(Float)
    opened_at = Column(DateTime)
    closed_at = Column(DateTime, nullable=True)

class Transaction(Base):
    __tablename__ = "transactions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    type = Column(String, index=True)       # deposit | withdrawal | profit | loss
    amount = Column(Float)                  # signed: + adds to balance, - removes
    status = Column(String, default="pending", index=True)  # pending | completed | rejected
    method = Column(String, nullable=True)
    reference = Column(String, nullable=True)    # deposit proof / txid
    destination = Column(String, nullable=True)  # withdrawal address or account
    description = Column(String, nullable=True)
    admin_note = Column(String, nullable=True)
    position_id = Column(Integer, nullable=True, unique=True)  # one result row per trade
    created_at = Column(DateTime, default=datetime.utcnow)
    processed_at = Column(DateTime, nullable=True)
    processed_by = Column(Integer, nullable=True)