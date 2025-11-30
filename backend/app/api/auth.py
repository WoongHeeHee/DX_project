"""
인증 관련 API 엔드포인트
"""

from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from google.auth.transport import requests
from google.oauth2 import id_token

from app.db.database import get_db
from app.db.models import User
from app.models.schemas import Token, GoogleAuthRequest, UserCreate, User as UserSchema
from app.config import settings

router = APIRouter()
security = HTTPBearer()


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """JWT 액세스 토큰 생성"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """JWT 토큰 검증"""
    try:
        payload = jwt.decode(credentials.credentials, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="토큰이 유효하지 않습니다",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return user_id
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="토큰이 유효하지 않습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(user_id: str = Depends(verify_token), db: Session = Depends(get_db)):
    """현재 사용자 정보 가져오기"""
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="사용자를 찾을 수 없습니다"
        )
    return user


@router.post("/google", response_model=Token)
async def google_auth(auth_request: GoogleAuthRequest, db: Session = Depends(get_db)):
    """Google OAuth 인증"""
    try:
        # Google ID 토큰 검증
        idinfo = id_token.verify_oauth2_token(
            auth_request.code, 
            requests.Request(), 
            settings.GOOGLE_CLIENT_ID
        )
        
        google_id = idinfo['sub']
        email = idinfo.get('email')
        name = idinfo.get('name', '')
        
        # 기존 사용자 확인
        user = db.query(User).filter(User.google_id == google_id).first()
        
        if not user:
            # 새 사용자 생성
            user_data = UserCreate(
                google_id=google_id,
                email=email,
                display_name=name,
                locale="ko"
            )
            user = User(**user_data.dict())
            db.add(user)
            db.commit()
            db.refresh(user)
        
        # JWT 토큰 생성
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.id)}, 
            expires_delta=access_token_expires
        )
        
        return Token(
            access_token=access_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Google 인증 실패: {str(e)}"
        )


@router.get("/me", response_model=UserSchema)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """현재 사용자 정보 조회"""
    return current_user


@router.post("/refresh", response_model=Token)
async def refresh_token(current_user: User = Depends(get_current_user)):
    """토큰 갱신"""
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(current_user.id)}, 
        expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )
