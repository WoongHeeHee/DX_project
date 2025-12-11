"""
사진 처리 관련 Celery 작업
비회원 제보, 회원 리뷰, 회원 검색 케이스를 명확히 분리하여 처리
"""

import logging

from app.tasks.celery_app import celery_app
from app.services.photo_processing_service import PhotoProcessingService

logger = logging.getLogger(__name__)


@celery_app.task(bind=True, max_retries=3)
def process_photo(self, photo_id: str):
    """
    사진 처리 메인 작업
    photo_type에 따라 적절한 처리 함수 호출
    
    Args:
        photo_id: Photo ID
    """
    try:
        logger.info(f"사진 처리 시작: photo_id={photo_id}")
        
        from app.db.database import SessionLocal
        from app.db.models import Photo
        
        db = SessionLocal()
        
        try:
            # 사진 정보 조회
            photo = db.query(Photo).filter(Photo.id == photo_id).first()
            if not photo:
                logger.error(f"사진을 찾을 수 없음: {photo_id}")
                return
            
            # photo_type에 따라 처리
            photo_processor = PhotoProcessingService(db)
            
            if photo.photo_type == 'report':
                # 비회원 가게 제보
                result = photo_processor.process_report_photo(photo)
                logger.info(f"제보 사진 처리 완료: photo_id={photo_id}, result={result}")
                
            elif photo.photo_type == 'review':
                # 회원 리뷰용 사진
                result = photo_processor.process_review_photo(photo)
                logger.info(f"리뷰 사진 처리 완료: photo_id={photo_id}, result={result}")
                
            elif photo.photo_type == 'search':
                # ⚠️ 검색용 사진은 저장하지 않음
                # 이 코드는 실행되지 않아야 하지만, 방어적 코드로 남김
                logger.error(f"⚠️ 검색용 사진이 Celery worker에 전달됨: photo_id={photo_id} (시스템 오류!)")
                from app.services.s3_service import S3Service
                s3_service = S3Service()
                s3_service.delete_object(photo.s3_key)
                if photo.thumbnail_s3_key:
                    s3_service.delete_object(photo.thumbnail_s3_key)
                db.delete(photo)
                db.commit()
                logger.warning(f"검색용 사진 삭제 완료: photo_id={photo_id}")
                
            else:
                logger.warning(f"알 수 없는 photo_type: {photo.photo_type}, photo_id={photo_id}")
                # 기본 처리: processed=True만 설정
                photo.processed = True
                db.commit()
                
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"사진 처리 실패: {photo_id}, 오류: {e}", exc_info=True)
        raise self.retry(countdown=60, exc=e)


@celery_app.task(bind=True, max_retries=3)
def generate_thumbnails(self, photo_id: str, s3_key: str):
    """
    썸네일 생성 작업
    
    Args:
        photo_id: Photo ID
        s3_key: 원본 이미지 S3 키
    """
    try:
        logger.info(f"썸네일 생성 시작: photo_id={photo_id}")
        
        from app.db.database import SessionLocal
        from app.db.models import Photo
        from app.services.s3_service import S3Service
        from PIL import Image
        from io import BytesIO
        import tempfile
        
        db = SessionLocal()
        
        try:
            photo = db.query(Photo).filter(Photo.id == photo_id).first()
            if not photo:
                logger.error(f"사진을 찾을 수 없음: {photo_id}")
                return
            
            # 검색용 사진은 썸네일 생성 스킵
            if photo.photo_type == 'search':
                logger.info(f"검색용 사진 썸네일 생성 스킵: {photo_id}")
                return
            
            # S3에서 이미지 다운로드
            s3_service = S3Service()
            image_bytes = s3_service.download_object_to_bytes(s3_key)
            if not image_bytes:
                logger.error(f"이미지 다운로드 실패: {photo_id}")
                raise Exception("이미지 다운로드 실패")
            
            # PIL로 이미지 열기
            image = Image.open(BytesIO(image_bytes))
            
            # 썸네일 크기 설정
            thumbnail_sizes = [(300, 300), (150, 150)]
            
            for width, height in thumbnail_sizes:
                # 썸네일 생성
                thumbnail = image.copy()
                thumbnail.thumbnail((width, height), Image.Resampling.LANCZOS)
                
                # S3에 업로드
                thumbnail_key = f"thumbnails/{photo_id}_{width}x{height}.jpg"
                
                with tempfile.NamedTemporaryFile(suffix='.jpg') as temp_file:
                    thumbnail.save(temp_file.name, format='JPEG', quality=85)
                    s3_service.upload_file(
                        temp_file.name, 
                        thumbnail_key, 
                        content_type='image/jpeg'
                    )
            
            # 데이터베이스 업데이트
            photo.thumbnail_s3_key = f"thumbnails/{photo_id}_300x300.jpg"
            db.commit()
            
            logger.info(f"썸네일 생성 완료: photo_id={photo_id}")
            
        finally:
            db.close()
        
    except Exception as e:
        logger.error(f"썸네일 생성 실패: {photo_id}, 오류: {e}", exc_info=True)
        raise self.retry(countdown=60, exc=e)
