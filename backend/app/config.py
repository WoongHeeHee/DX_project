"""
환경 설정 관리
"""

import os
from typing import List, Union, Any
from pydantic import field_validator, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """애플리케이션 설정"""
    
    # 기본 설정
    APP_NAME: str = "시장 탐방 API"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    # 데이터베이스 설정
    DATABASE_URL: str = "postgresql://postgres:password@localhost:5432/market_explorer"
    
    # Redis 설정
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # JWT 설정
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Google OAuth 설정
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""
    
    # AWS S3 설정
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    AWS_REGION: str = "ap-northeast-2"
    S3_BUCKET_NAME: str = "market-explorer-photos"
    
    # OpenAI 설정
    OPENAI_API_KEY: str = ""
    
    # Pinecone 설정
    PINECONE_API_KEY: str = ""
    PINECONE_ENVIRONMENT: str = "us-west1-gcp"
    PINECONE_INDEX_NAME: str = "market-explorer"
    
    # 지도 API 설정
    MAP_PROVIDER: str = "kakao"  # kakao | naver
    KAKAO_API_KEY: str = ""
    NAVER_CLIENT_ID: str = ""
    NAVER_CLIENT_SECRET: str = ""
    
    # CORS 설정 (환경 변수에서 읽되, 문제가 있으면 기본값 사용)
    ALLOWED_ORIGINS: str = Field(
        default="http://localhost:3000,http://localhost:8080,http://localhost:50000,http://127.0.0.1:50000",
        description="CORS 허용 오리진 (쉼표로 구분)"
    )
    
    # Celery 설정
    CELERY_BROKER_URL: str = "redis://localhost:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/0"
    
    # 사진 보존 정책
    PHOTO_RETENTION_DAYS: int = 180
    
    # 추천 시스템 설정
    RECOMMENDATION_FACTORS: int = 32
    RECOMMENDATION_ALPHA: float = 0.1
    
    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Any) -> str:
        """ALLOWED_ORIGINS 검증 및 정규화"""
        default_origins = "http://localhost:3000,http://localhost:8080,http://localhost:50000,http://127.0.0.1:50000"
        if v is None:
            return default_origins
        if isinstance(v, str):
            if v.strip() == "":
                return default_origins
            return v
        if isinstance(v, list):
            return ",".join(str(item) for item in v)
        return default_origins
    
    def get_allowed_origins_list(self) -> List[str]:
        """CORS 허용 오리진 리스트 반환"""
        default_origins = ["http://localhost:3000", "http://localhost:8080", "http://localhost:50000", "http://127.0.0.1:50000"]
        if not self.ALLOWED_ORIGINS or self.ALLOWED_ORIGINS.strip() == "":
            return default_origins
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",") if origin.strip()]
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_ignore_empty=True,  # 빈 환경 변수 무시
        env_nested_delimiter="__",  # 중첩 환경 변수 구분자
        case_sensitive=True,
        extra="ignore",  # 환경 변수에 없는 필드는 무시
        validate_default=True,
        populate_by_name=True  # 필드 이름과 별칭 모두 허용
    )


# 전역 설정 인스턴스
def _create_settings() -> Settings:
    """설정 인스턴스 생성 (오류 처리 포함)"""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        # ALLOWED_ORIGINS 환경 변수가 빈 문자열이면 제거
        if "ALLOWED_ORIGINS" in os.environ:
            allowed_origins_env = os.environ.get("ALLOWED_ORIGINS", "").strip()
            if allowed_origins_env == "":
                # 빈 문자열이면 환경 변수에서 제거하여 기본값 사용
                del os.environ["ALLOWED_ORIGINS"]
                logger.debug("ALLOWED_ORIGINS가 빈 문자열이어서 기본값 사용")
        
        return Settings()
    except Exception as e:
        logger.warning(f"환경 변수 로드 중 오류 발생: {e}, 기본값으로 재시도")
        
        # 문제가 될 수 있는 환경 변수 제거 후 재시도
        problematic_vars = ["ALLOWED_ORIGINS"]
        original_env = {}
        for var in problematic_vars:
            if var in os.environ:
                original_env[var] = os.environ[var]
                del os.environ[var]
        
        try:
            return Settings()
        except Exception as e2:
            logger.error(f"설정 로드 실패: {e2}, 최소 설정으로 생성")
            # 환경 변수 복원
            os.environ.update(original_env)
            # 문제가 되는 환경 변수만 제거하고 재시도
            for var in problematic_vars:
                if var in os.environ:
                    del os.environ[var]
            # 다시 시도
            try:
                return Settings()
            except Exception:
                # 마지막 시도: 모든 환경 변수 무시하고 기본값만 사용
                from pydantic_settings import SettingsConfigDict
                minimal_config = SettingsConfigDict(
                    env_file=None,  # .env 파일 무시
                    extra="ignore",
                    case_sensitive=True
                )
                return Settings(model_config=minimal_config)


settings = _create_settings()
