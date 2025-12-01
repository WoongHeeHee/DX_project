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
from app.services.image_processor_service import ImageProcessorService

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
    """OpenAI를 사용한 이미지 분석 (제보용/리뷰용 사진 처리)"""
    try:
        logger.info(f"이미지 분석 시작: {photo_id}")
        
        from app.db.database import SessionLocal
        from app.db.models import Photo
        
        db = SessionLocal()
        try:
            photo = db.query(Photo).filter(Photo.id == photo_id).first()
            if not photo:
                logger.error(f"사진을 찾을 수 없음: {photo_id}")
                return
            
            # 이미지 처리 서비스 초기화
            image_processor = ImageProcessorService(db)
            
            # 사진 타입에 따라 처리
            if photo.photo_type == 'report':
                # 제보용 사진 처리
                result = image_processor.process_store_photo(image_url)
                
                # 적합하지 않은 사진은 삭제
                if result.get('usage') == 'rejected':
                    logger.info(f"부적합한 제보 사진 삭제: {photo_id}")
                    s3_service = S3Service()
                    s3_service.delete_object(photo.s3_key)
                    if photo.thumbnail_s3_key:
                        s3_service.delete_object(photo.thumbnail_s3_key)
                    db.delete(photo)
                    db.commit()
                    return
                
                # 가게 사진인 경우 삭제 (structure.md 참고)
                if result.get('type') == 'store_photo' and result.get('is_suitable'):
                    logger.info(f"가게 사진 삭제 (사용 안함): {photo_id}")
                    s3_service = S3Service()
                    s3_service.delete_object(photo.s3_key)
                    if photo.thumbnail_s3_key:
                        s3_service.delete_object(photo.thumbnail_s3_key)
                    db.delete(photo)
                    db.commit()
                    return
                
                # 음식 사진인 경우 parsed_items 저장
                photo.parsed_items = result
                photo.processed = True
                db.commit()
                
                # 여러 음식인 경우 crop된 사진 저장 작업 실행
                if result.get('type') == 'multiple_foods':
                    process_cropped_photos.delay(photo_id, image_url, result.get('foods', []))
                    
            elif photo.photo_type == 'review':
                # 리뷰용 사진 처리
                if photo.shop_id:
                    result = image_processor.process_food_trail([image_url], str(photo.shop_id))
                    photo.parsed_items = result
                    photo.processed = True
                    db.commit()
                    
                    # 여러 음식인 경우 crop된 사진 저장
                    if result.get('detected_foods'):
                        foods = result.get('detected_foods', [])
                        process_cropped_photos.delay(photo_id, image_url, foods)
                else:
                    logger.warning(f"리뷰 사진에 shop_id가 없음: {photo_id}")
            
            else:
                # 기본 분석 (기존 로직)
                openai_service = OpenAIService()
                analysis_result = openai_service.analyze_food_image(image_url)
                
                if analysis_result.get('is_food') and analysis_result.get('detected_foods'):
                    match_with_menu_items.delay(photo_id, image_url, analysis_result)
                
                photo.parsed_items = analysis_result
                photo.processed = True
                db.commit()
            
        finally:
            db.close()
        
        logger.info(f"이미지 분석 완료: {photo_id}")
        
    except Exception as e:
        logger.error(f"이미지 분석 실패: {photo_id}, 오류: {e}")
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


@celery_app.task(bind=True, max_retries=3)
def process_cropped_photos(self, photo_id: str, original_image_url: str, foods: List[Dict]):
    """
    여러 음식이 있는 사진을 crop하여 각각 저장
    
    Args:
        photo_id: 원본 사진 ID
        original_image_url: 원본 이미지 URL
        foods: 탐지된 음식 리스트 (bbox 포함)
    """
    try:
        logger.info(f"Crop된 사진 처리 시작: {photo_id}")
        
        from app.db.database import SessionLocal
        from app.db.models import Photo
        import requests
        from PIL import Image
        from io import BytesIO
        import uuid
        from datetime import datetime
        
        db = SessionLocal()
        s3_service = S3Service()
        
        try:
            original_photo = db.query(Photo).filter(Photo.id == photo_id).first()
            if not original_photo:
                logger.error(f"원본 사진을 찾을 수 없음: {photo_id}")
                return
            
            # 원본 이미지 다운로드
            response = requests.get(original_image_url)
            response.raise_for_status()
            image = Image.open(BytesIO(response.content))
            image_width, image_height = image.size
            
            # 각 음식에 대해 crop 및 저장
            for i, food in enumerate(foods):
                bbox = food.get('bbox')
                if not bbox or len(bbox) != 4:
                    continue
                
                # bbox를 픽셀 좌표로 변환 (0~1 정규화된 값)
                x1, y1, x2, y2 = bbox
                crop_x1 = int(x1 * image_width)
                crop_y1 = int(y1 * image_height)
                crop_x2 = int(x2 * image_width)
                crop_y2 = int(y2 * image_height)
                
                # 이미지 crop
                cropped_image = image.crop((crop_x1, crop_y1, crop_x2, crop_y2))
                
                # S3에 업로드
                timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
                crop_s3_key = f"photos/crops/{photo_id}_{i}_{uuid.uuid4().hex}.jpg"
                
                # 임시 파일로 저장 후 업로드
                import tempfile
                with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_file:
                    cropped_image.save(temp_file.name, format='JPEG', quality=90)
                    s3_service.upload_file(
                        temp_file.name,
                        crop_s3_key,
                        content_type='image/jpeg'
                    )
                
                # crop된 사진 정보를 parsed_items에 추가
                if original_photo.parsed_items:
                    if 'cropped_photos' not in original_photo.parsed_items:
                        original_photo.parsed_items['cropped_photos'] = []
                    original_photo.parsed_items['cropped_photos'].append({
                        'crop_index': i,
                        's3_key': crop_s3_key,
                        'menu': food.get('menu'),
                        'bbox': bbox,
                        'confidence': food.get('confidence', 0.0)
                    })
            
            db.commit()
            logger.info(f"Crop된 사진 처리 완료: {photo_id}")
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"Crop된 사진 처리 실패: {photo_id}, 오류: {e}")
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
