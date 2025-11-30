"""
사진 업로드 관련 API 엔드포인트
"""

import uuid
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import Photo, User
from app.models.schemas import (
    PhotoUploadInit, 
    PhotoUploadInitResponse, 
    PhotoUploadComplete,
    BaseResponse,
    Photo as PhotoSchema
)
from app.api.auth import get_current_user, verify_token
from app.services.s3_service import S3Service
from app.tasks.photo_tasks import process_photo

router = APIRouter()


@router.post("/photo-init", response_model=PhotoUploadInitResponse)
async def init_photo_upload(
    request: PhotoUploadInit,
    http_request: Request,
    db: Session = Depends(get_db)
):
    """사진 업로드 초기화 - presigned URL 생성"""
    
    # 선택적 사용자 인증 처리
    current_user = None
    if request.is_member:
        authorization = http_request.headers.get("Authorization", "")
        if authorization and authorization.startswith("Bearer "):
            try:
                token = authorization.replace("Bearer ", "")
                user_id = verify_token(token)
                current_user = db.query(User).filter(User.id == user_id).first()
            except:
                pass
    
    # S3 키 생성
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    file_extension = "jpg"  # 기본 확장자
    s3_key = f"photos/{timestamp}_{uuid.uuid4().hex}.{file_extension}"
    
    # 업로드 토큰 생성 (비회원용)
    upload_token = str(uuid.uuid4()) if not request.is_member else None
    
    try:
        # S3 서비스를 통해 presigned URL 생성
        s3_service = S3Service()
        presigned_url = s3_service.generate_presigned_upload_url(
            s3_key=s3_key,
            expires_in=3600  # 1시간
        )
        
        return PhotoUploadInitResponse(
            success=True,
            presigned_url=presigned_url,
            upload_token=upload_token or "",
            s3_key=s3_key,
            message="사진 업로드 URL이 생성되었습니다"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"업로드 URL 생성 실패: {str(e)}"
        )


@router.post("/photo-complete", response_model=BaseResponse)
async def complete_photo_upload(
    request: PhotoUploadComplete,
    db: Session = Depends(get_db)
):
    """사진 업로드 완료 처리"""
    
    try:
        # 사진 레코드 생성
        photo = Photo(
            uploader_user_id=request.uploader_user_id,
            upload_token=request.upload_token,
            s3_key=request.s3_key,
            lat=request.lat,
            lng=request.lng,
            taken_at=request.taken_at,
            processed=False
        )
        
        db.add(photo)
        db.commit()
        db.refresh(photo)
        
        # 비동기 사진 처리 작업 큐에 추가
        process_photo.delay(str(photo.id))
        
        return BaseResponse(
            success=True,
            message="사진이 성공적으로 업로드되었습니다. 처리 중입니다."
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사진 업로드 완료 처리 실패: {str(e)}"
        )


@router.get("/photo/{photo_id}", response_model=PhotoSchema)
async def get_photo(photo_id: str, db: Session = Depends(get_db)):
    """사진 정보 조회"""
    photo = db.query(Photo).filter(Photo.id == photo_id).first()
    if not photo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="사진을 찾을 수 없습니다"
        )
    return photo


@router.get("/my-photos", response_model=list[PhotoSchema])
async def get_my_photos(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 20,
    offset: int = 0
):
    """내 사진 목록 조회"""
    photos = db.query(Photo).filter(
        Photo.uploader_user_id == current_user.id
    ).order_by(Photo.created_at.desc()).offset(offset).limit(limit).all()
    
    return photos


@router.delete("/photo/{photo_id}", response_model=BaseResponse)
async def delete_photo(
    photo_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """사진 삭제"""
    photo = db.query(Photo).filter(
        Photo.id == photo_id,
        Photo.uploader_user_id == current_user.id
    ).first()
    
    if not photo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="사진을 찾을 수 없거나 삭제 권한이 없습니다"
        )
    
    try:
        # S3에서 파일 삭제
        s3_service = S3Service()
        s3_service.delete_object(photo.s3_key)
        if photo.thumbnail_s3_key:
            s3_service.delete_object(photo.thumbnail_s3_key)
        
        # DB에서 레코드 삭제
        db.delete(photo)
        db.commit()
        
        return BaseResponse(
            success=True,
            message="사진이 성공적으로 삭제되었습니다"
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사진 삭제 실패: {str(e)}"
        )
