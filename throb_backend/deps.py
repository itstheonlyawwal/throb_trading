import os
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

try:
    from jose import jwt
except ImportError:
    import jwt  # PyJWT

import auth
from database import SessionLocal
from models import User

bearer_scheme = HTTPBearer()
SECRET_KEY = getattr(auth, "SECRET_KEY", os.getenv("SECRET_KEY", ""))
ALGORITHM = getattr(auth, "ALGORITHM", "HS256")


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
    try:
        payload = jwt.decode(creds.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        sub = payload.get("sub")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    if sub is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    if str(sub).isdigit():
        user = db.query(User).filter(User.id == int(sub)).first()
    else:
        user = db.query(User).filter(User.email == str(sub)).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user