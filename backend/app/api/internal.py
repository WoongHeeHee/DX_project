"""
내부 프록시 엔드포인트
OpenAI Vision API가 presigned URL을 다운로드할 수 없을 때 fallback으로 사용
"""

import logging
import uuid
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import Photo
from app.services.s3_service import S3Service
from app.config import settings

logger = logging.getLogger(__name__)
router = APIRouter()


# 임시 토큰 저장소 (실제 운영에서는 Redis 등 사용 권장)
_temp_tokens = {}


def generate_temp_token(photo_id: str, expires_in: int = 300) -> str:
    """임시 토큰 생성 (5분 만료)"""
    token = str(uuid.uuid4())
    expires_at = datetime.utcnow() + timedelta(seconds=expires_in)
    _temp_tokens[token] = {
        "photo_id": photo_id,
        "expires_at": expires_at
    }
    return token


def verify_temp_token(token: str) -> Optional[str]:
    """임시 토큰 검증 및 photo_id 반환"""
    if token not in _temp_tokens:
        return None
    
    token_data = _temp_tokens[token]
    if datetime.utcnow() > token_data["expires_at"]:
        # 만료된 토큰 삭제
        del _temp_tokens[token]
        return None
    
    return token_data["photo_id"]


@router.get("/serve_photo/{photo_id}")
async def serve_photo(
    photo_id: str,
    token: Optional[str] = Query(None, description="임시 토큰 (보안용)"),
    db: Session = Depends(get_db)
):
    """
    사진 프록시 엔드포인트 (OpenAI Vision API fallback용)
    
    S3에서 이미지를 다운로드하여 스트리밍으로 반환합니다.
    OpenAI가 presigned URL을 다운로드할 수 없을 때 사용됩니다.
    
    보안: token 파라미터로 접근 제어 (선택적, 운영 환경에서는 필수 권장)
    """
    try:
        # 토큰 검증 (제공된 경우)
        if token:
            verified_photo_id = verify_temp_token(token)
            if not verified_photo_id or verified_photo_id != photo_id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="유효하지 않은 토큰입니다"
                )
        
        # 사진 정보 조회
        photo = db.query(Photo).filter(Photo.id == photo_id).first()
        if not photo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사진을 찾을 수 없습니다"
            )
        
        # S3에서 이미지 다운로드
        s3_service = S3Service()
        image_bytes = s3_service.download_object_to_bytes(photo.s3_key)
        
        if not image_bytes:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="이미지를 다운로드할 수 없습니다"
            )
        
        # Content-Type 결정
        content_type = "image/jpeg"
        if photo.s3_key.endswith('.png'):
            content_type = "image/png"
        elif photo.s3_key.endswith('.gif'):
            content_type = "image/gif"
        elif photo.s3_key.endswith('.webp'):
            content_type = "image/webp"
        
        logger.info(f"프록시 엔드포인트로 이미지 서빙: photo_id={photo_id}, content_type={content_type}, size={len(image_bytes)} bytes")
        
        # 스트리밍 응답 반환
        from io import BytesIO
        return StreamingResponse(
            BytesIO(image_bytes),
            media_type=content_type,
            headers={
                "Content-Length": str(len(image_bytes)),
                "Cache-Control": "public, max-age=300"  # 5분 캐시
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"프록시 엔드포인트 오류: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"이미지 서빙 실패: {str(e)}"
        )

