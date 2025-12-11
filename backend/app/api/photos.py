"""
사진 업로드 관련 API 엔드포인트

3가지 사진 처리 케이스:
1. 비회원 가게 제보 (photo_type='report'): 음식 사진 확인 → 메뉴 개수 확인 → DB 존재 확인 → crop → S3 저장
2. 회원 리뷰용 사진 (photo_type='review'): 음식 사진 확인 → 메뉴 개수 확인 → DB 존재 확인 → crop → S3 저장
3. 회원 메뉴 검색 (photo_type='search'): menu_matcher로 매칭 → 매칭 실패 시 사진 폐기 → 사진 저장하지 않음
"""

import uuid
import logging
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request, UploadFile, File, Form
from sqlalchemy.orm import Session
from jose import JWTError, jwt

from app.db.database import get_db
from app.db.models import Photo, User, Shop
from app.models.schemas import (
    PhotoPresignResponse,
    PhotoUploadRequest,
    PhotoUploadResponse,
    PhotoUploadInit, 
    PhotoUploadInitResponse, 
    PhotoUploadComplete,
    PhotoReportComplete,
    BaseResponse,
    Photo as PhotoSchema
)
from app.api.auth import get_current_user
from app.config import settings
from app.services.s3_service import S3Service
from app.tasks.photo_tasks import process_photo

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/presign", response_model=PhotoPresignResponse)
async def presign_photo_upload(
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    사진 업로드용 presigned URL 발급 (새 스펙)
    
    Returns:
        {
            "upload_url": "S3 업로드용 presigned URL",
            "file_url": "업로드된 파일의 URL (S3 키)"
        }
    """
    try:
        # S3 키 생성
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        s3_key = f"photos/{timestamp}_{uuid.uuid4().hex}.jpg"
        
        # S3 서비스를 통해 presigned URL 생성
        s3_service = S3Service()
        upload_url = s3_service.generate_presigned_upload_url(
            s3_key=s3_key,
            expires_in=3600  # 1시간
        )
        
        # file_url은 S3 키 (클라이언트가 업로드 후 사용할 URL)
        file_url = s3_key
        
        logger.info(f"Presigned URL 생성 완료: s3_key={s3_key}")
        
        return PhotoPresignResponse(
            upload_url=upload_url,
            file_url=file_url
        )
        
    except Exception as e:
        logger.error(f"Presigned URL 생성 실패: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Presigned URL 생성 실패: {str(e)}"
        )


@router.post("", response_model=PhotoUploadResponse)
async def upload_photo(
    request: PhotoUploadRequest,
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    사진 업로드 완료 처리 (새 스펙)
    
    처리 흐름:
    - review/report: Celery로 자동 처리 (crop → S3 저장 → menu 매칭 → DB 저장)
    - search: 저장 없이 menu 인식 결과만 즉시 반환
    
    Args:
        request: PhotoUploadRequest (photo_url, lat, lng, photo_type)
        current_user: 현재 사용자 (선택)
        db: 데이터베이스 세션
    
    Returns:
        PhotoUploadResponse:
        - review/report: photo_ids 리스트 (처리 중이므로 빈 리스트)
        - search: matched_menu (또는 None)
    """
    logger.info(f"사진 업로드 완료 요청: photo_url={request.photo_url[:50]}..., photo_type={request.photo_type}")
    
    try:
        # photo_url에서 S3 키 추출 (URL이면 키만 추출, 키면 그대로 사용)
        s3_key = request.photo_url
        if s3_key.startswith("http://") or s3_key.startswith("https://"):
            # URL에서 키 추출
            if "/photos/" in request.photo_url:
                s3_key = request.photo_url.split("/photos/")[-1]
                s3_key = f"photos/{s3_key}"
            else:
                # 전체 경로를 키로 사용
                parts = request.photo_url.split("/")
                s3_key = "/".join(parts[3:])  # bucket name 이후 부분
        
        if request.photo_type == 'search':
            # search: 저장 없이 menu 인식 결과만 즉시 반환
            from app.services.photo_processing_service import PhotoProcessingService
            
            photo_processor = PhotoProcessingService(db)
            
            # presigned download URL 생성
            s3_service = S3Service()
            image_url = s3_service.generate_presigned_download_url(
                s3_key,
                expires_in=300
            )
            
            # menu 매칭
            matched_menu = photo_processor.process_search_photo(image_url)
            
            return PhotoUploadResponse(
                success=True,
                message="메뉴 인식 완료",
                matched_menu=matched_menu,
                photo_ids=None
            )
        
        elif request.photo_type in ['review', 'report']:
            # review/report: 동기 처리로 즉시 photo_ids 반환
            from app.services.photo_processing_service import PhotoProcessingService
            
            uploader_user_id = str(current_user.id) if current_user else None
            
            # Photo 레코드 생성 (처리 전)
            photo = Photo(
                uploader_user_id=uploader_user_id,
                s3_key=s3_key,
                lat=request.lat,
                lng=request.lng,
                taken_at=datetime.utcnow(),
                photo_type=request.photo_type,
                processed=False
            )
            
            db.add(photo)
            db.commit()
            db.refresh(photo)
            
            logger.info(f"Photo 레코드 생성 완료: photo_id={photo.id}, photo_type={photo.photo_type}")
            
            # 동기 처리로 즉시 처리 및 photo_ids 반환
            photo_processor = PhotoProcessingService(db)
            
            try:
                if request.photo_type == 'review':
                    result = photo_processor.process_review_photo(photo)
                elif request.photo_type == 'report':
                    result = photo_processor.process_report_photo(photo)
                else:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"지원하지 않는 photo_type: {request.photo_type}"
                    )
            except Exception as e:
                logger.error(f"사진 처리 중 예외 발생: {e}", exc_info=True)
                raise
            
            # 저장된 photo_ids 추출
            saved_photo_ids = result.get("saved_photo_ids", [])
            
            if not result.get("success", False):
                # 처리 실패
                logger.warning(f"사진 처리 실패: {result.get('message')}")
                return PhotoUploadResponse(
                    success=False,
                    message=result.get("message", "사진 처리에 실패했습니다."),
                    photo_ids=[],
                    matched_menu=None
                )
            
            logger.info(f"사진 처리 완료: photo_type={request.photo_type}, saved_count={len(saved_photo_ids)}")
            
            return PhotoUploadResponse(
                success=True,
                message=result.get("message", f"{len(saved_photo_ids)}개의 사진이 저장되었습니다."),
                photo_ids=saved_photo_ids,  # 실제 저장된 photo_ids 반환
                matched_menu=None
            )
        
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"지원하지 않는 photo_type: {request.photo_type}"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"사진 업로드 완료 처리 실패: {e}", exc_info=True)
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사진 업로드 완료 처리 실패: {str(e)}"
        )


@router.post("/photo-init", response_model=PhotoUploadInitResponse)
async def init_photo_upload(
    request: PhotoUploadInit,
    http_request: Request,
    db: Session = Depends(get_db)
):
    """
    사진 업로드 초기화 - presigned URL 생성
    
    Args:
        request: PhotoUploadInit (is_member, photo_type 등 포함)
        http_request: HTTP 요청 객체 (인증 토큰 추출용)
        db: 데이터베이스 세션
        
    Returns:
        PhotoUploadInitResponse: presigned URL 및 업로드 토큰
    """
    logger.info(f"사진 업로드 초기화 요청: is_member={request.is_member}, photo_type={getattr(request, 'photo_type', None)}")
    
    try:
        # 선택적 사용자 인증 처리
        current_user = None
        if request.is_member:
            authorization = http_request.headers.get("Authorization", "")
            if authorization and authorization.startswith("Bearer "):
                try:
                    token = authorization.replace("Bearer ", "")
                    # 토큰 디코딩
                    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
                    user_id_str = payload.get("sub")
                    if user_id_str:
                        # 문자열 user_id로 사용자 조회 (DB에서 TEXT 타입으로 저장됨)
                        current_user = db.query(User).filter(User.id == user_id_str).first()
                        logger.info(f"인증된 사용자: user_id={user_id_str}")
                except (JWTError, Exception) as e:
                    # 토큰 검증 실패 시 무시 (선택적 인증)
                    logger.warning(f"토큰 검증 실패 (선택적 인증이므로 계속 진행): {e}")
        
        # S3 키 생성
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        file_extension = "jpg"  # 기본 확장자
        s3_key = f"photos/{timestamp}_{uuid.uuid4().hex}.{file_extension}"
        
        # 업로드 토큰 생성 (비회원용)
        upload_token = str(uuid.uuid4()) if not request.is_member else None
        
        logger.info(f"S3 서비스 초기화 시작: bucket={settings.S3_BUCKET_NAME}, region={settings.AWS_REGION}")
        
        # S3 서비스를 통해 presigned URL 생성
        s3_service = S3Service()
        logger.info(f"S3 서비스 초기화 완료")
        
        logger.info(f"Presigned URL 생성 시작: s3_key={s3_key}")
        presigned_url = s3_service.generate_presigned_upload_url(
            s3_key=s3_key,
            expires_in=3600  # 1시간
        )
        
        logger.info(f"Presigned URL 생성 완료: s3_key={s3_key}, upload_token={upload_token[:20] if upload_token else None}...")
        
        return PhotoUploadInitResponse(
            success=True,
            presigned_url=presigned_url,
            upload_token=upload_token or "",
            s3_key=s3_key,
            message="사진 업로드 URL이 생성되었습니다"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        error_detail = str(e)
        logger.error(f"업로드 URL 생성 실패: {error_detail}", exc_info=True)
        # 더 자세한 에러 정보 로깅
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"업로드 URL 생성 실패: {error_detail}"
        )


@router.post("/photo-complete", response_model=BaseResponse)
async def complete_photo_upload(
    request: PhotoUploadComplete,
    db: Session = Depends(get_db)
):
    """
    사진 업로드 완료 처리
    
    처리 흐름:
    1. Photo 레코드 생성
    2. Celery 비동기 작업 큐에 추가 (photo_type에 따라 적절한 처리 수행)
    
    Args:
        request: PhotoUploadComplete (s3_key, lat, lng, taken_at, photo_type 등 포함)
        db: 데이터베이스 세션
        
    Returns:
        BaseResponse: 업로드 완료 메시지
    """
    logger.info(f"사진 업로드 완료 요청: s3_key={request.s3_key}, photo_type={request.photo_type or 'report'}")
    
    # 검색용 사진(photo_type='search')은 절대 저장하지 않음
    if request.photo_type == 'search':
        logger.warning("검색용 사진(photo_type='search')은 이 엔드포인트를 사용할 수 없습니다. /search/image-upload 엔드포인트를 사용하세요.")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="검색용 사진은 저장하지 않습니다. /search/image-upload 엔드포인트를 사용하세요."
        )
    
    try:
        # 사진 레코드 생성
        photo = Photo(
            uploader_user_id=request.uploader_user_id,
            upload_token=request.upload_token,
            s3_key=request.s3_key,
            lat=request.lat,
            lng=request.lng,
            taken_at=request.taken_at,
            photo_type=request.photo_type or "report",
            processed=False
        )
        
        db.add(photo)
        db.commit()
        db.refresh(photo)
        
        logger.info(f"Photo 레코드 생성 완료: photo_id={photo.id}, photo_type={photo.photo_type}")
        
        # 비동기 사진 처리 작업 큐에 추가
        # photo_type에 따라 적절한 처리 수행:
        # - 'report': 비회원 제보 사진 처리
        # - 'review': 회원 리뷰용 사진 처리
        process_photo.delay(str(photo.id))
        
        logger.info(f"사진 처리 작업 큐에 추가: photo_id={photo.id}")
        
        return BaseResponse(
            success=True,
            message="사진이 성공적으로 업로드되었습니다. 처리 중입니다."
        )
        
    except Exception as e:
        logger.error(f"사진 업로드 완료 처리 실패: {e}", exc_info=True)
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사진 업로드 완료 처리 실패: {str(e)}"
        )


@router.post("/report-complete", response_model=BaseResponse)
async def complete_photo_report(
    request: PhotoReportComplete,
    db: Session = Depends(get_db)
):
    """제보 완료 처리: 가게 선택 후 shop_id 저장 및 영업 상태 업데이트"""
    try:
        # 업로드 토큰으로 사진 찾기
        photo = db.query(Photo).filter(
            Photo.upload_token == request.upload_token
        ).first()
        
        if not photo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사진을 찾을 수 없습니다. 업로드 토큰이 유효하지 않습니다."
            )
        
        # 가게 존재 확인
        shop = db.query(Shop).filter(Shop.id == request.shop_id).first()
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="가게를 찾을 수 없습니다"
            )
        
        # 사진에 shop_id 연결
        photo.shop_id = request.shop_id
        
        # 가게 영업 상태 업데이트 (last_reported_open_at)
        from datetime import datetime, timezone
        shop.last_reported_open_at = datetime.now(timezone.utc)
        
        db.commit()
        db.refresh(photo)
        
        return BaseResponse(
            success=True,
            message="제보가 성공적으로 완료되었습니다"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"제보 완료 처리 실패: {str(e)}"
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


@router.post("/upload", response_model=PhotoUploadResponse)
async def upload_review_photo(
    image: UploadFile = File(..., description="리뷰용 사진 파일"),
    lat: float = Form(..., description="위도"),
    lng: float = Form(..., description="경도"),
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    리뷰 사진 업로드 (설계 의도에 정확히 맞춘 구현)
    
    처리 흐름:
    1. 원본 사진 1장 + GPS (lat, lng) 받기
    2. ML 모델로 음식 판별 및 여러 crop 생성
    3. 각 crop에 대해:
       - menu_items에 존재 확인 → 없으면 폐기
       - S3에 crop 이미지 업로드
       - closest shop 찾기
       - DB.photo에 insert
    
    반환:
        저장된 photo_id 리스트
    """
    try:
        # 이미지 파일 읽기
        image_bytes = await image.read()
        if not image_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미지 파일이 비어있습니다"
            )
        
        # PhotoProcessingService로 처리
        from app.services.photo_processing_service import PhotoProcessingService
        
        photo_processor = PhotoProcessingService(db)
        uploader_user_id = str(current_user.id) if current_user else None
        
        saved_photo_ids = photo_processor.process_review_photo_upload(
            image_bytes=image_bytes,
            lat=lat,
            lng=lng,
            uploader_user_id=uploader_user_id
        )
        
        if not saved_photo_ids:
            return PhotoUploadResponse(
                success=True,
                message="저장할 수 있는 메뉴가 없어 모든 사진이 폐기되었습니다",
                photo_ids=[]
            )
        
        return PhotoUploadResponse(
            success=True,
            message=f"{len(saved_photo_ids)}개의 사진이 저장되었습니다",
            photo_ids=saved_photo_ids
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"리뷰 사진 업로드 중 오류 발생: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사진 업로드 중 오류가 발생했습니다: {str(e)}"
        )
