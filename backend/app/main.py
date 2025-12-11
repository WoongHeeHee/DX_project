"""
시장 탐방 서비스 FastAPI 메인 애플리케이션
"""

from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
from starlette.middleware.trustedhost import TrustedHostMiddleware
import uvicorn
import logging

from app.config import settings
from app.api import auth, users, markets, shops, photos, search, recommendations, diary, market_photos, menus, internal
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

# Cloudflare 터널을 통한 HTTPS 요청을 올바르게 처리하기 위한 미들웨어
@app.middleware("http")
async def trust_proxy_headers(request: Request, call_next):
    """프록시(Cloudflare) 헤더를 신뢰하여 HTTPS 요청을 올바르게 처리"""
    # Cloudflare 터널을 통해 들어온 요청의 경우, X-Forwarded-Proto 헤더를 확인
    forwarded_proto = request.headers.get("X-Forwarded-Proto", "")
    forwarded_host = request.headers.get("X-Forwarded-Host", "")
    
    # HTTPS 요청인 경우 URL을 HTTPS로 설정
    if forwarded_proto == "https" or forwarded_proto == "http" and forwarded_host:
        # 요청 URL을 업데이트하여 HTTPS를 유지
        if hasattr(request, 'url') and request.url.scheme == "http":
            # URL 객체는 불변이므로, 새로운 URL을 생성하여 사용
            # 실제로는 응답 헤더에서 처리
            pass
    
    response = await call_next(request)
    
    # HTTPS 요청인 경우 Location 헤더를 HTTPS로 변환
    if forwarded_proto == "https":
        location = response.headers.get("Location")
        if location and location.startswith("http://"):
            # HTTP 리다이렉트를 HTTPS로 변환
            response.headers["Location"] = location.replace("http://", "https://", 1)
            logger.info(f"리다이렉트 URL을 HTTPS로 변환: {location} -> {response.headers['Location']}")
    
    return response

# CORS 설정
allowed_origins = settings.get_allowed_origins_list()
logger.info(f"CORS 허용 오리진: {allowed_origins}")

# OPTIONS 요청을 명시적으로 처리하는 미들웨어 (CORS 미들웨어 이전에 실행)
@app.middleware("http")
async def handle_options_requests(request, call_next):
    """OPTIONS(CORS preflight) 요청을 라우터 이전에 처리"""
    if request.method == "OPTIONS":
        origin = request.headers.get("origin", "")
        allowed = origin in allowed_origins

        from fastapi.responses import Response

        response = Response(status_code=200 if allowed else 403)
        if origin:
            response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, Accept, Origin, X-Requested-With"
        response.headers["Access-Control-Allow-Credentials"] = "true"
        response.headers["Access-Control-Max-Age"] = "86400"

        # 상세한 로깅 (MD 파일 형식)
        logger.info("═══════════════════════════════════════════════════")
        logger.info("🔄 CORS Preflight 요청 처리")
        logger.info("───────────────────────────────────────────────────")
        logger.info("경로: %s", request.url.path)
        logger.info("Origin: %s", origin or "none")
        if allowed:
            logger.info("✅ Origin이 허용 목록에 포함됨")
            logger.info("✅ OPTIONS 요청 처리 완료 - CORS 헤더 추가")
        else:
            logger.warning("❌ Origin이 허용 목록에 포함되지 않음")
            logger.warning("허용된 오리진: %s", allowed_origins)
        logger.info("═══════════════════════════════════════════════════")
        
        return response

    return await call_next(request)

# CORS 미들웨어
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],  # 모든 HTTP 메서드 허용
    allow_headers=["*"],  # 모든 헤더 허용
)

# 요청 로깅 미들웨어
@app.middleware("http")
async def log_requests(request, call_next):
    """요청/응답 상세 로깅"""
    origin = request.headers.get("origin", "none")
    method = request.method
    path = request.url.path

    if method != "OPTIONS":
        logger.info("═══════════════════════════════════════════════════")
        logger.info("📥 [%s] %s", method, path)
        logger.info("───────────────────────────────────────────────────")
        logger.info("Origin: %s", origin)
        if origin in allowed_origins:
            logger.info("✅ Origin이 허용 목록에 포함됨")
        else:
            logger.warning("⚠️ Origin이 허용 목록에 포함되지 않음 (CORS 미들웨어에서 처리)")

    response = await call_next(request)

    if method != "OPTIONS":
        cors_origin = response.headers.get("access-control-allow-origin")
        logger.info("📤 응답 상태 코드: %s", response.status_code)
        if cors_origin:
            logger.info("✅ CORS 헤더 포함됨: Access-Control-Allow-Origin=%s", cors_origin)
        else:
            logger.warning("⚠️ CORS 헤더 없음")
        logger.info("═══════════════════════════════════════════════════")

    return response

# 보안 스키마
security = HTTPBearer()

# 데이터베이스 테이블 생성 및 마이그레이션
@app.on_event("startup")
async def startup_event():
    """애플리케이션 시작 시 실행"""
    logger.info("시장 탐방 API 서버 시작")
    
    # Alembic 마이그레이션 자동 실행
    try:
        from alembic.config import Config
        from alembic import command
        import os
        from pathlib import Path
        
        # alembic.ini 파일 경로 찾기
        current_dir = Path(__file__).parent
        alembic_ini_path = current_dir.parent / "alembic.ini"
        
        if not alembic_ini_path.exists():
            logger.warning(f"alembic.ini 파일을 찾을 수 없습니다: {alembic_ini_path}")
            raise FileNotFoundError(f"alembic.ini not found at {alembic_ini_path}")
        
        alembic_cfg = Config(str(alembic_ini_path))
        alembic_cfg.set_main_option("sqlalchemy.url", settings.DATABASE_URL)
        
        logger.info("데이터베이스 마이그레이션 실행 중...")
        command.upgrade(alembic_cfg, "head")
        logger.info("데이터베이스 마이그레이션 완료")
    except Exception as e:
        logger.error(f"마이그레이션 실행 중 오류 발생: {e}", exc_info=True)
        # 개발 환경에서만 테이블 자동 생성 (fallback)
        if settings.ENVIRONMENT == "development":
            logger.warning("마이그레이션 실패, 테이블 자동 생성 시도...")
            try:
                Base.metadata.create_all(bind=engine)
                logger.info("테이블 자동 생성 완료")
            except Exception as e2:
                logger.error(f"테이블 자동 생성 실패: {e2}", exc_info=True)

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
app.include_router(photos.router, prefix="/photos", tags=["사진 업로드 (새 스펙)"])
app.include_router(search.router, prefix="/search", tags=["검색"])
app.include_router(recommendations.router, prefix="/recommendations", tags=["추천"])
app.include_router(diary.router, prefix="/diary", tags=["다이어리"])
app.include_router(market_photos.router, prefix="/markets", tags=["지도-시장"])
app.include_router(menus.router, prefix="/menus", tags=["메뉴"])

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True if settings.ENVIRONMENT == "development" else False
    )
