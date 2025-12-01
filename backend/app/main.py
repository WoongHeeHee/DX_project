"""
시장 탐방 서비스 FastAPI 메인 애플리케이션
"""

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
import uvicorn
import logging

from app.config import settings
from app.api import auth, users, markets, shops, photos, search, recommendations, diary, market_photos
from app.db.database import engine, Base

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI 앱 생성
app = FastAPI(
    title="시장 탐방 API",
    description="방한 외국인을 위한 시장 탐방 서비스 API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_allowed_origins_list(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 보안 스키마
security = HTTPBearer()

# 데이터베이스 테이블 생성
@app.on_event("startup")
async def startup_event():
    """애플리케이션 시작 시 실행"""
    logger.info("시장 탐방 API 서버 시작")
    # 개발 환경에서만 테이블 자동 생성 (운영에서는 Alembic 사용)
    if settings.ENVIRONMENT == "development":
        Base.metadata.create_all(bind=engine)

@app.on_event("shutdown")
async def shutdown_event():
    """애플리케이션 종료 시 실행"""
    logger.info("시장 탐방 API 서버 종료")

# 헬스체크 엔드포인트
@app.get("/health")
async def health_check():
    """서버 상태 확인"""
    return {
        "status": "healthy",
        "service": "시장 탐방 API",
        "version": "1.0.0"
    }

# API 라우터 등록
app.include_router(auth.router, prefix="/auth", tags=["인증"])
app.include_router(users.router, prefix="/users", tags=["사용자"])
app.include_router(markets.router, prefix="/markets", tags=["시장"])
app.include_router(shops.router, prefix="/shops", tags=["가게"])
app.include_router(photos.router, prefix="/uploads", tags=["사진 업로드"])
app.include_router(search.router, prefix="/search", tags=["검색"])
app.include_router(recommendations.router, prefix="/recommendations", tags=["추천"])
app.include_router(diary.router, prefix="/diary", tags=["다이어리"])
app.include_router(market_photos.router, prefix="/markets", tags=["지도-시장"])

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True if settings.ENVIRONMENT == "development" else False
    )
