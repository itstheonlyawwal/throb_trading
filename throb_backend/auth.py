import os
from datetime import datetime, timedelta
from dotenv import load_dotenv
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import jwt, JWTError
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database import get_db
from models import User

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError("SECRET_KEY is missing. Add it to your .env file.")

ALGORITHM = "HS256"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
bearer_scheme = HTTPBearer()

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=7)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

    def decode_token(token: str) -> int:
        """Returns the user id inside a valid token, or raises 401."""
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            return int(payload["sub"])
        except (JWTError, KeyError, ValueError):
            raise HTTPException(status_code=401, detail="Invalid or expired token")

            def get_current_user(
                creds: HTTPAuthorizationCredentials = Depends(bearer_scheme),
                db: Session = Depends(get_db),
            ) -> User:
                """Use as: user: User = Depends(get_current_user)"""
                user_id = decode_token(creds.credentials)
                user = db.get(User, user_id)
                if not user:
                    raise HTTPException(status_code=401, detail="User not found")
                return user