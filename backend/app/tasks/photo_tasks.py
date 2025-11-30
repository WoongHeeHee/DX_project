"""
사진 처리 관련 Celery 작업
"""

import logging
from typing import Dict, Any, List
from PIL import Image
import requests
from io import BytesIO

from app.tasks.celery_app import celery_app
from app.services.openai_service import OpenAIService
from app.services.pinecone_service import PineconeService
from app.services.s3_service import S3Service

logger = logging.getLogger(__name__)


@celery_app.task(bind=True, max_retries=3)
def process_photo(self, photo_id: str):
    """사진 처리 메인 작업"""
    try:
        logger.info(f"사진 처리 시작: {photo_id}")
        
        # 데이터베이스 연결
        from app.db.database import SessionLocal
        from app.db.models import Photo, MenuItem
        
        db = SessionLocal()
        
        try:
            # 사진 정보 조회
            photo = db.query(Photo).filter(Photo.id == photo_id).first()
            if not photo:
                logger.error(f"사진을 찾을 수 없음: {photo_id}")
                return
            
            # S3에서 이미지 URL 생성
            s3_service = S3Service()
            image_url = s3_service.generate_presigned_download_url(photo.s3_key)
            
            # 1. 썸네일 생성
            thumbnail_task = generate_thumbnails.delay(photo_id, image_url)
            
            # 2. OpenAI 이미지 분석
            analysis_task = analyze_image_with_openai.delay(photo_id, image_url)
            
            # 작업 완료 대기 (비동기적으로 처리하거나 체인으로 연결 가능)
            logger.info(f"사진 처리 작업 큐에 추가됨: {photo_id}")
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"사진 처리 실패: {photo_id}, 오류: {e}")
        raise self.retry(countdown=60, exc=e)


@celery_app.task(bind=True, max_retries=3)
def generate_thumbnails(self, photo_id: str, image_url: str):
    """썸네일 생성 작업"""
    try:
        logger.info(f"썸네일 생성 시작: {photo_id}")
        
        # 이미지 다운로드
        response = requests.get(image_url)
        response.raise_for_status()
        
        # PIL로 이미지 열기
        image = Image.open(BytesIO(response.content))
        
        # 썸네일 크기 설정
        thumbnail_sizes = [(300, 300), (150, 150)]
        
        s3_service = S3Service()
        
        for width, height in thumbnail_sizes:
            # 썸네일 생성
            thumbnail = image.copy()
            thumbnail.thumbnail((width, height), Image.Resampling.LANCZOS)
            
            # 썸네일을 바이트로 변환
            thumbnail_buffer = BytesIO()
            thumbnail.save(thumbnail_buffer, format='JPEG', quality=85)
            thumbnail_buffer.seek(0)
            
            # S3에 업로드
            thumbnail_key = f"thumbnails/{photo_id}_{width}x{height}.jpg"
            
            # 임시 파일로 저장 후 업로드
            import tempfile
            with tempfile.NamedTemporaryFile(suffix='.jpg') as temp_file:
                thumbnail.save(temp_file.name, format='JPEG', quality=85)
                s3_service.upload_file(
                    temp_file.name, 
                    thumbnail_key, 
                    content_type='image/jpeg'
                )
        
        # 데이터베이스 업데이트
        from app.db.database import SessionLocal
        from app.db.models import Photo
        
        db = SessionLocal()
        try:
            photo = db.query(Photo).filter(Photo.id == photo_id).first()
            if photo:
                photo.thumbnail_s3_key = f"thumbnails/{photo_id}_300x300.jpg"
                db.commit()
        finally:
            db.close()
        
        logger.info(f"썸네일 생성 완료: {photo_id}")
        
    except Exception as e:
        logger.error(f"썸네일 생성 실패: {photo_id}, 오류: {e}")
        raise self.retry(countdown=60, exc=e)


@celery_app.task(bind=True, max_retries=3)
def analyze_image_with_openai(self, photo_id: str, image_url: str):
    """OpenAI를 사용한 이미지 분석"""
    try:
        logger.info(f"OpenAI 이미지 분석 시작: {photo_id}")
        
        openai_service = OpenAIService()
        
        # 이미지 분석
        analysis_result = openai_service.analyze_food_image(image_url)
        
        # 메뉴 매칭이 필요한 경우
        if analysis_result.get('is_food') and analysis_result.get('detected_foods'):
            # 메뉴 매칭 작업 실행
            match_with_menu_items.delay(photo_id, image_url, analysis_result)
        
        # 분석 결과를 데이터베이스에 저장
        from app.db.database import SessionLocal
        from app.db.models import Photo
        
        db = SessionLocal()
        try:
            photo = db.query(Photo).filter(Photo.id == photo_id).first()
            if photo:
                photo.parsed_items = analysis_result
                photo.processed = True
                db.commit()
        finally:
            db.close()
        
        logger.info(f"OpenAI 이미지 분석 완료: {photo_id}")
        
    except Exception as e:
        logger.error(f"OpenAI 이미지 분석 실패: {photo_id}, 오류: {e}")
        raise self.retry(countdown=60, exc=e)


@celery_app.task(bind=True, max_retries=3)
def match_with_menu_items(self, photo_id: str, image_url: str, analysis_result: Dict[str, Any]):
    """메뉴 아이템과 매칭"""
    try:
        logger.info(f"메뉴 매칭 시작: {photo_id}")
        
        from app.db.database import SessionLocal
        from app.db.models import MenuItem, Photo
        
        db = SessionLocal()
        
        try:
            # 모든 메뉴 아이템 조회
            menu_items = db.query(MenuItem).all()
            menu_names = [item.name for item in menu_items]
            
            if not menu_names:
                logger.warning("메뉴 아이템이 없음")
                return
            
            openai_service = OpenAIService()
            pinecone_service = PineconeService()
            
            # 각 감지된 음식에 대해 처리
            detected_foods = analysis_result.get('detected_foods', [])
            matched_results = []
            
            for i, detected_food in enumerate(detected_foods):
                # 메뉴 매칭
                match_result = openai_service.match_menu_item(
                    image_url, 
                    menu_names, 
                    detected_food.get('name')
                )
                
                # 이미지 임베딩 생성
                embedding = openai_service.generate_image_embedding(image_url)
                
                if embedding:
                    # Pinecone에 임베딩 저장
                    metadata = {
                        "detected_food_name": detected_food.get('name'),
                        "matched_menu": match_result.get('matched_menu'),
                        "confidence": match_result.get('confidence', 0.0),
                        "bbox": detected_food.get('bbox', [])
                    }
                    
                    pinecone_service.upsert_photo_embedding(
                        photo_id, i, embedding, metadata
                    )
                
                matched_results.append({
                    "crop_index": i,
                    "detected_food": detected_food,
                    "match_result": match_result
                })
            
            # 매칭 결과를 데이터베이스에 업데이트
            photo = db.query(Photo).filter(Photo.id == photo_id).first()
            if photo:
                updated_parsed_items = photo.parsed_items or {}
                updated_parsed_items['matched_results'] = matched_results
                photo.parsed_items = updated_parsed_items
                db.commit()
            
            logger.info(f"메뉴 매칭 완료: {photo_id}")
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"메뉴 매칭 실패: {photo_id}, 오류: {e}")
        raise self.retry(countdown=60, exc=e)


@celery_app.task
def batch_process_menu_embeddings():
    """메뉴 아이템 임베딩 배치 처리"""
    try:
        logger.info("메뉴 임베딩 배치 처리 시작")
        
        from app.db.database import SessionLocal
        from app.db.models import MenuItem
        
        db = SessionLocal()
        
        try:
            menu_items = db.query(MenuItem).all()
            
            openai_service = OpenAIService()
            pinecone_service = PineconeService()
            
            menu_embeddings = []
            
            for menu_item in menu_items:
                # 메뉴 설명 텍스트 생성
                description = f"{menu_item.name}"
                if menu_item.description:
                    description += f" {menu_item.description}"
                
                # 임베딩 생성
                embedding = openai_service.generate_embedding(description)
                
                if embedding:
                    menu_embeddings.append({
                        "menu_item_id": str(menu_item.id),
                        "embedding": embedding,
                        "metadata": {
                            "name": menu_item.name,
                            "name_en": menu_item.name_en,
                            "description": menu_item.description,
                            "spice_level": menu_item.spice_level,
                            "market_id": str(menu_item.market_id)
                        }
                    })
            
            # 배치로 Pinecone에 업로드
            if menu_embeddings:
                pinecone_service.batch_upsert_menu_embeddings(menu_embeddings)
                logger.info(f"메뉴 임베딩 {len(menu_embeddings)}개 처리 완료")
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"메뉴 임베딩 배치 처리 실패: {e}")
        raise
