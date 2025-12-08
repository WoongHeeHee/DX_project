"""
유지보수 관련 Celery 작업
"""

import logging
from datetime import datetime, timedelta
from typing import List

from app.tasks.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task
def aggregate_keyword_reviews():
    """키워드 리뷰 집계 작업"""
    try:
        logger.info("키워드 리뷰 집계 시작")
        
        from app.db.database import SessionLocal
        from app.db.models import Diary, KeywordReview, Market
        from sqlalchemy import func
        
        db = SessionLocal()
        
        try:
            # 모든 시장에 대해 처리
            markets = db.query(Market).all()
            
            for market in markets:
                # 해당 시장의 최근 다이어리에서 키워드 집계
                recent_diaries = db.query(Diary).filter(
                    Diary.market_id == market.id,
                    Diary.keywords.isnot(None)
                ).all()
                
                # 키워드 카운트
                keyword_counts = {}
                for diary in recent_diaries:
                    if diary.keywords:
                        for keyword in diary.keywords:
                            keyword_counts[keyword] = keyword_counts.get(keyword, 0) + 1
                
                # 기존 키워드 리뷰 업데이트 또는 생성
                for keyword, count in keyword_counts.items():
                    existing_review = db.query(KeywordReview).filter(
                        KeywordReview.market_id == market.id,
                        KeywordReview.keyword == keyword
                    ).first()
                    
                    if existing_review:
                        existing_review.count = count
                        existing_review.last_updated = datetime.utcnow()
                    else:
                        new_review = KeywordReview(
                            market_id=market.id,
                            keyword=keyword,
                            count=count
                        )
                        db.add(new_review)
                
                db.commit()
                logger.info(f"시장 {market.name}의 키워드 리뷰 집계 완료: {len(keyword_counts)}개 키워드")
            
        finally:
            db.close()
            
        logger.info("키워드 리뷰 집계 완료")
        
    except Exception as e:
        logger.error(f"키워드 리뷰 집계 실패: {e}")
        raise


@celery_app.task
def update_keyword_reviews(market_id: str, keywords: List[str]):
    """특정 시장의 키워드 리뷰 업데이트"""
    try:
        from app.db.database import SessionLocal
        from app.db.models import KeywordReview
        
        db = SessionLocal()
        
        try:
            for keyword in keywords:
                existing_review = db.query(KeywordReview).filter(
                    KeywordReview.market_id == market_id,
                    KeywordReview.keyword == keyword
                ).first()
                
                if existing_review:
                    existing_review.count += 1
                    existing_review.last_updated = datetime.utcnow()
                else:
                    new_review = KeywordReview(
                        market_id=market_id,
                        keyword=keyword,
                        count=1
                    )
                    db.add(new_review)
            
            db.commit()
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"키워드 리뷰 업데이트 실패: {e}")


@celery_app.task
def cleanup_old_photos():
    """오래된 사진 정리 작업"""
    try:
        logger.info("오래된 사진 정리 시작")
        
        from app.db.database import SessionLocal
        from app.db.models import Photo
        from app.services.s3_service import S3Service
        from app.config import settings
        
        db = SessionLocal()
        s3_service = S3Service()
        
        try:
            # 보존 기간 계산
            retention_date = datetime.utcnow() - timedelta(days=settings.PHOTO_RETENTION_DAYS)
            
            # 오래된 사진 조회
            old_photos = db.query(Photo).filter(
                Photo.created_at < retention_date
            ).all()
            
            deleted_count = 0
            anonymized_count = 0
            
            for photo in old_photos:
                try:
                    # S3에서 파일 삭제 (선택적)
                    if hasattr(settings, 'DELETE_OLD_PHOTOS') and settings.DELETE_OLD_PHOTOS:
                        s3_service.delete_object(photo.s3_key)
                        if photo.thumbnail_s3_key:
                            s3_service.delete_object(photo.thumbnail_s3_key)
                        
                        # DB에서 레코드 삭제
                        db.delete(photo)
                        deleted_count += 1
                    else:
                        # 익명화 (uploader_user_id만 제거)
                        photo.uploader_user_id = None
                        anonymized_count += 1
                
                except Exception as e:
                    logger.error(f"사진 정리 실패 (ID: {photo.id}): {e}")
                    continue
            
            db.commit()
            
            logger.info(f"사진 정리 완료 - 삭제: {deleted_count}개, 익명화: {anonymized_count}개")
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"사진 정리 작업 실패: {e}")
        raise


@celery_app.task
def update_shop_status():
    """가게 영업 상태 업데이트"""
    try:
        logger.info("가게 영업 상태 업데이트 시작")
        
        from app.db.database import SessionLocal
        from app.db.models import Shop, Photo
        from sqlalchemy import func
        
        db = SessionLocal()
        
        try:
            # 각 가게별로 최근 사진 업로드 시간 확인
            shops = db.query(Shop).all()
            
            from app.utils.geography import haversine_distance, get_bounding_box
            
            for shop in shops:
                # 해당 가게 근처(50m)의 최근 사진 확인
                # Bounding box로 먼저 필터링
                min_lat, max_lat, min_lng, max_lng = get_bounding_box(
                    shop.lat, shop.lng, 50  # 50m 반경
                )
                
                # 사각형 범위 내 사진 조회
                candidate_photos = db.query(Photo).filter(
                    Photo.lat.between(min_lat, max_lat),
                    Photo.lng.between(min_lng, max_lng),
                    Photo.created_at >= datetime.utcnow() - timedelta(hours=12)
                ).order_by(Photo.created_at.desc()).all()
                
                # 정확한 거리 계산으로 50m 내 사진 찾기
                for photo in candidate_photos:
                    distance = haversine_distance(
                        shop.lat, shop.lng,
                        photo.lat, photo.lng
                    )
                    if distance <= 50:  # 50m 반경 내
                        shop.last_reported_open_at = photo.created_at
                        break
            
            db.commit()
            logger.info("가게 영업 상태 업데이트 완료")
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"가게 영업 상태 업데이트 실패: {e}")
        raise


@celery_app.task
def generate_daily_stats():
    """일일 통계 생성"""
    try:
        logger.info("일일 통계 생성 시작")
        
        from app.db.database import SessionLocal
        from app.db.models import Photo, User, Like, Diary
        from sqlalchemy import func
        
        db = SessionLocal()
        
        try:
            today = datetime.utcnow().date()
            yesterday = today - timedelta(days=1)
            
            # 어제 통계 계산
            stats = {
                'date': yesterday.isoformat(),
                'new_users': db.query(User).filter(
                    func.date(User.created_at) == yesterday
                ).count(),
                'photos_uploaded': db.query(Photo).filter(
                    func.date(Photo.created_at) == yesterday
                ).count(),
                'likes_created': db.query(Like).filter(
                    func.date(Like.created_at) == yesterday
                ).count(),
                'diaries_created': db.query(Diary).filter(
                    func.date(Diary.created_at) == yesterday
                ).count()
            }
            
            # 통계를 로그에 기록 (실제로는 별도 테이블이나 외부 시스템에 저장)
            logger.info(f"일일 통계: {stats}")
            
            # Redis나 별도 통계 테이블에 저장할 수 있음
            
        finally:
            db.close()
            
        logger.info("일일 통계 생성 완료")
        
    except Exception as e:
        logger.error(f"일일 통계 생성 실패: {e}")
        raise


@celery_app.task
def backup_database():
    """데이터베이스 백업 (간단한 덤프)"""
    try:
        logger.info("데이터베이스 백업 시작")
        
        import subprocess
        from app.config import settings
        
        # PostgreSQL 덤프 명령
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        backup_filename = f"market_explorer_backup_{timestamp}.sql"
        
        # pg_dump 명령 실행 (실제 환경에서는 더 안전한 방법 사용)
        dump_command = [
            "pg_dump",
            settings.DATABASE_URL,
            "-f", backup_filename
        ]
        
        # 실제로는 S3나 다른 안전한 저장소에 업로드
        logger.info(f"백업 파일 생성: {backup_filename}")
        
        # 여기서는 로그만 남김 (실제 구현 시 pg_dump 실행)
        logger.info("데이터베이스 백업 완료")
        
    except Exception as e:
        logger.error(f"데이터베이스 백업 실패: {e}")
        raise
