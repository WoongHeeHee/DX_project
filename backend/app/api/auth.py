"""
인증 관련 API 엔드포인트 - 완전 재설계
"""

from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from google.auth.transport import requests
from google.oauth2 import id_token
import logging

from app.db.database import get_db
from app.db.models import User
from app.models.schemas import Token, GoogleAuthRequest, UserCreate, User as UserSchema
from app.config import settings

# 로거 설정
logger = logging.getLogger(__name__)

# 라우터 및 보안 스키마
router = APIRouter()
security = HTTPBearer()


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """JWT 액세스 토큰 생성"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """JWT 토큰 검증 및 사용자 ID 반환"""
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
    except JWTError as e:
        logger.error("verify_token 실패: %s", str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="토큰이 유효하지 않습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        logger.error("verify_token 예외: %s", str(e), exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="토큰 검증 중 오류가 발생했습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(user_id: str = Depends(verify_token), db: Session = Depends(get_db)) -> User:
    """현재 사용자 정보 가져오기"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        return user
    except HTTPException:
        raise
    except Exception as e:
        logger.error("get_current_user 예외 user_id=%s error=%s", user_id, str(e), exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사용자 조회 중 오류가 발생했습니다: {str(e)}"
        )


# 선택적 인증을 위한 보안 스키마
optional_security = HTTPBearer(auto_error=False)


def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(optional_security),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """
    선택적 사용자 인증 (토큰이 있으면 사용자 반환, 없으면 None)
    """
    if credentials is None:
        return None
    
    try:
        payload = jwt.decode(credentials.credentials, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            return None
        
        # 문자열 user_id로 사용자 조회 (DB에서 TEXT 타입으로 저장됨)
        user = db.query(User).filter(User.id == user_id).first()
        return user
    except (JWTError, Exception):
        return None


@router.post("/google", response_model=Token)
async def google_auth(auth_request: GoogleAuthRequest, db: Session = Depends(get_db)):
    """Google OAuth 인증 엔드포인트"""
    logger.info("Auth: /auth/google 요청 수신")
    
    if not settings.GOOGLE_CLIENT_ID or settings.GOOGLE_CLIENT_ID.strip() == "":
        logger.error("GOOGLE_CLIENT_ID가 설정되지 않음")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="서버 설정 오류: Google Client ID가 설정되지 않았습니다."
        )

    if not auth_request.id_token or auth_request.id_token.strip() == "":
        logger.error("id_token이 제공되지 않음")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="id_token이 제공되지 않았습니다."
        )
    
    id_token_str = auth_request.id_token.strip()
    logger.info(f"id_token 수신됨 (길이: {len(id_token_str)}자)")
    
    try:
        logger.info("Google ID 토큰 검증 시도")
        idinfo = id_token.verify_oauth2_token(
            id_token_str, 
            requests.Request(), 
            settings.GOOGLE_CLIENT_ID
        )
        
        logger.info(
            "Google 토큰 검증 성공 sub=%s email=%s",
            idinfo.get("sub"),
            idinfo.get("email"),
        )

        google_id = idinfo['sub']
        email = idinfo.get('email')
        name = idinfo.get('name', '')

        user = db.query(User).filter(User.google_id == google_id).first()
        
        if not user:
            logger.info("새 사용자 생성 email=%s", email)
            user_data = UserCreate(
                google_id=google_id,
                email=email,
                display_name=name if name else "User",
                locale="ko",
                spice_level=None,
                adventure=None,
                korean_experience=None,
                country=None,
                birth_yyyy_mm=None,
            )
            user = User(**user_data.dict())
            db.add(user)
            db.commit()
            db.refresh(user)
            logger.info("새 사용자 생성 완료 user_id=%s email=%s", user.id, email)
        else:
            logger.info("기존 사용자 로그인 user_id=%s email=%s", user.id, email)
        
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.id)}, 
            expires_delta=access_token_expires
        )
        
        logger.info("JWT 토큰 생성 완료 user_id=%s", user.id)
        
        return Token(
            access_token=access_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
        
    except ValueError as e:
        error_msg = str(e)
        logger.error("Google ID 토큰 검증 실패: %s", error_msg)

        detail_msg = "Google 인증 실패: " + error_msg
        if "Invalid token signature" in error_msg:
            detail_msg = "토큰 서명이 유효하지 않습니다. Google Client ID가 올바른지 확인하세요."
        elif "Token's client ID does not match" in error_msg or "audience" in error_msg.lower():
            detail_msg = (
                "토큰의 Client ID가 서버 설정과 일치하지 않습니다. "
                f"서버 Client ID: {settings.GOOGLE_CLIENT_ID[:20]}..."
            )
        elif "Token expired" in error_msg:
            detail_msg = "토큰이 만료되었습니다. 다시 로그인해주세요."

        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail_msg)
    except Exception as e:
        logger.error("Google 인증 중 오류: %s", str(e), exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="서버 오류가 발생했습니다.")


@router.get("/me", response_model=UserSchema)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """현재 사용자 정보 조회"""
    try:
        return current_user
    except Exception as e:
        logger.error("[GET] /auth/me 실패 user_id=%s error=%s", getattr(current_user, "id", None), str(e), exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사용자 정보 조회 중 오류가 발생했습니다: {str(e)}"
        )


@router.post("/refresh", response_model=Token)
async def refresh_token(current_user: User = Depends(get_current_user)):
    """JWT 토큰 갱신"""
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(current_user.id)}, 
        expires_delta=access_token_expires
    )

    logger.info("토큰 갱신 완료 user_id=%s", current_user.id)

    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )
