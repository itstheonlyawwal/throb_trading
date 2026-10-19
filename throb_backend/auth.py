import os
from datetime import datetime, timedelta
from dotenv import load_dotenv
from fastapi import HTTPException
from jose import jwt, JWTError
from passlib.context import CryptContext

load_dotenv()

SECRET_KEY = os.getenv("36e68a93ecc5686cd93e6fe7d5af285ff580184165b1e6b3c0e1bf9de64a3da2")
ALGORITHM = "HS256"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

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