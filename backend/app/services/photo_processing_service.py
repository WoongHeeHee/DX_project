"""
사진 처리 서비스
비회원 제보, 회원 리뷰, 회원 검색 케이스를 명확히 분리하여 처리

핵심 원칙:
- menu_matcher.py가 메뉴 매칭의 단일 진실 소스 (Single Source of Truth)
- report/review: 원본 → bbox 탐지 → crop → menu_matcher 매칭 → 저장
- search: 원본 → menu_matcher 매칭 → 결과만 반환 (저장 없음)
"""

import logging
import uuid
from typing import Dict, List, Optional
from datetime import datetime
from io import BytesIO
from sqlalchemy.orm import Session

from app.services.vision_service import VisionService
from app.services.s3_service import S3Service
from app.services.menu_matcher_service import MenuMatcherService
from app.db.models import Photo, MenuItem, Shop
from app.utils.image_utils import crop_image_by_bbox, validate_bbox
from app.utils.geo_utils import find_nearest_shop
from app.config import settings

logger = logging.getLogger(__name__)


class PhotoProcessingService:
    """
    사진 처리 서비스
    3가지 케이스를 명확히 분리하여 처리:
    1. 비회원 가게 제보 (photo_type='report')
    2. 회원 리뷰용 사진 (photo_type='review')
    3. 회원 메뉴 검색 (photo_type='search') - 저장하지 않음
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.vision_service = VisionService()
        self.s3_service = S3Service()
        self.menu_matcher = MenuMatcherService(db)
    
    def process_review_photo(self, photo: Photo) -> Dict[str, any]:
        """
        회원 리뷰용 사진 처리 (photo_type='review')
        
        처리 흐름:
        [1] presigned URL로 원본 사진 다운로드
        [2] detect_foods_with_bbox() → bbox 목록 획득
        [3] Python(Pillow)로 crop N개 생성
        [4] for each crop:
            - matched = menu_matcher.match(crop)  # 단일 진실 소스
            - if matched is None: continue (폐기)
            - presign → S3 업로드 → Photo DB 저장
        [5] 원본 사진 processed=True 업데이트 및 정리
        
        Args:
            photo: Photo 객체 (원본 사진)
        
        Returns:
            {
                "success": bool,
                "saved_count": int,
                "saved_photo_ids": List[str],
                "rejected": bool,
                "message": str
            }
        """
        logger.info(f"리뷰 사진 처리 시작: photo_id={photo.id}, s3_key={photo.s3_key}")
        
        try:
            # [1] presigned URL로 원본 사진 다운로드
            original_image_bytes = self.s3_service.download_object_to_bytes(photo.s3_key)
            if not original_image_bytes:
                logger.error(f"원본 사진 다운로드 실패: photo_id={photo.id}")
                photo.processed = True
                self.db.commit()
                return {
                    "success": False,
                    "saved_count": 0,
                    "saved_photo_ids": [],
                    "rejected": True,
                    "message": "원본 사진을 다운로드할 수 없습니다"
                }
            
            # presigned URL 생성 (Vision API용) - OpenAI 호출 직전에 생성하여 TTL 문제 방지
            # TTL 3600초(1시간)로 설정하고 ResponseContentType 명시
            image_url = self.s3_service.generate_presigned_download_url(
                photo.s3_key,
                expires_in=3600,  # 1시간
                content_type="image/jpeg"
            )
            
            # presigned URL 검증 (HEAD 요청)
            if not self.s3_service.verify_presigned_url(image_url):
                logger.warning(f"Presigned URL 검증 실패, 재생성 시도: photo_id={photo.id}")
                image_url = self.s3_service.generate_presigned_download_url(
                    photo.s3_key,
                    expires_in=3600,
                    content_type="image/jpeg"
                )
            
            # [2] detect_foods_with_bbox() → bbox 목록 획득
            # menu_matcher에서 메뉴 목록 가져오기 (bbox 탐지 시 참고용)
            menu_candidates = self.menu_matcher.get_all_menus()
            detected_foods = self.vision_service.detect_foods_with_bbox(
                image_url,
                menu_candidates=menu_candidates
            )
            logger.info(f"탐지된 음식 수: {len(detected_foods) if detected_foods else 0}")
            
            if not detected_foods:
                logger.info(f"탐지된 음식이 없음, processed=True로 설정: photo_id={photo.id}")
                photo.processed = True
                self.db.commit()
                return {
                    "success": True,
                    "saved_count": 0,
                    "saved_photo_ids": [],
                    "rejected": False,
                    "message": "탐지된 음식이 없습니다"
                }
            
            # 가장 가까운 shop 찾기
            nearest_shop_id = find_nearest_shop(self.db, photo.lat, photo.lng)
            if nearest_shop_id:
                photo.shop_id = nearest_shop_id
                shop = self.db.query(Shop).filter(Shop.id == nearest_shop_id).first()
                if shop:
                    logger.info(f"가장 가까운 shop 찾음: shop_id={nearest_shop_id}, market_id={shop.market_id}")
            
            # [3] Python(Pillow)로 crop N개 생성
            # [4] for each crop: menu_matcher 매칭 → 저장
            saved_count = 0
            saved_photo_ids = []
            
            for i, food_item in enumerate(detected_foods):
                bbox = food_item.get("bbox")
                
                # bbox 유효성 검증
                if not validate_bbox(bbox):
                    logger.warning(f"Crop {i}: 유효하지 않은 bbox, 건너뜀")
                    continue
                
                # Python으로 실제 crop
                cropped_image_bytes = crop_image_by_bbox(original_image_bytes, bbox)
                if not cropped_image_bytes:
                    logger.warning(f"Crop {i}: 이미지 crop 실패, 건너뜀")
                    continue
                
                # crop 이미지를 임시로 S3에 업로드 (menu_matcher가 presigned URL 필요)
                timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
                crop_s3_key = f"photos/crops/{timestamp}_{uuid.uuid4().hex}.jpg"
                
                import tempfile
                with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_file:
                    temp_file.write(cropped_image_bytes)
                    temp_file.flush()
                    
                    success = self.s3_service.upload_file(
                        temp_file.name,
                        crop_s3_key,
                        content_type='image/jpeg'
                    )
                    
                    if not success:
                        logger.error(f"Crop {i}: S3 업로드 실패")
                        continue
                
                # crop 이미지의 presigned URL 생성 (menu_matcher 호출 직전에 생성)
                crop_image_url = self.s3_service.generate_presigned_download_url(
                    crop_s3_key,
                    expires_in=3600,  # 1시간
                    content_type="image/jpeg"
                )
                
                # presigned URL 검증
                if not self.s3_service.verify_presigned_url(crop_image_url):
                    logger.warning(f"Crop presigned URL 검증 실패, 재생성: crop_s3_key={crop_s3_key}")
                    crop_image_url = self.s3_service.generate_presigned_download_url(
                        crop_s3_key,
                        expires_in=3600,
                        content_type="image/jpeg"
                    )
                
                # [4] menu_matcher.match() - 단일 진실 소스로 메뉴 매칭
                matched_menu_name = self.menu_matcher.match_menu(
                    image_url=crop_image_url,
                    user_text=None
                )
                
                if not matched_menu_name:
                    logger.info(f"Crop {i}: menu_matcher 매칭 실패, 폐기")
                    # crop 이미지 삭제
                    self.s3_service.delete_object(crop_s3_key)
                    continue
                
                # menu_items에서 메뉴 조회
                menu_item = self.db.query(MenuItem).filter(
                    MenuItem.name == matched_menu_name
                ).first()
                
                if not menu_item:
                    logger.warning(f"Crop {i}: DB에 메뉴가 없음: {matched_menu_name}, 폐기")
                    self.s3_service.delete_object(crop_s3_key)
                    continue
                
                # 새로운 Photo 레코드 생성 (crop 이미지용)
                new_photo = Photo(
                    uploader_user_id=photo.uploader_user_id,
                    shop_id=nearest_shop_id,
                    menu_item_id=menu_item.id,
                    upload_token=photo.upload_token,
                    s3_key=crop_s3_key,
                    lat=photo.lat,
                    lng=photo.lng,
                    taken_at=photo.taken_at,
                    processed=True,
                    photo_type='review'
                )
                
                self.db.add(new_photo)
                self.db.flush()  # ID를 얻기 위해 flush
                self.db.refresh(new_photo)  # ID 갱신
                saved_count += 1
                saved_photo_ids.append(str(new_photo.id))
                logger.info(f"Crop {i}: 저장 완료 - menu={matched_menu_name}, photo_id={new_photo.id}")
            
            # [5] 원본 사진 삭제 (crop 이미지만 저장)
            self.s3_service.delete_object(photo.s3_key)
            self.db.delete(photo)
            self.db.commit()
            
            logger.info(f"리뷰 사진 처리 완료: 저장된 사진 수={saved_count}, photo_ids={saved_photo_ids}")
            
            return {
                "success": True,
                "saved_count": saved_count,
                "saved_photo_ids": saved_photo_ids,
                "rejected": False,
                "message": f"{saved_count}개의 사진이 저장되었습니다"
            }
            
        except Exception as e:
            logger.error(f"리뷰 사진 처리 중 오류 발생: photo_id={photo.id}, error={e}", exc_info=True)
            self.db.rollback()
            photo.processed = True
            self.db.commit()
            return {
                "success": False,
                "saved_count": 0,
                "saved_photo_ids": [],
                "rejected": True,
                "message": f"처리 중 오류가 발생했습니다: {str(e)}"
            }
    
    def process_report_photo(self, photo: Photo) -> Dict[str, any]:
        """
        비회원 가게 제보 사진 처리 (photo_type='report')
        
        리뷰 사진과 동일한 로직 사용
        """
        return self.process_review_photo(photo)
    
    def process_search_photo(self, image_url: str, user_text: Optional[str] = None) -> Optional[str]:
        """
        회원 메뉴 검색용 사진 처리 (photo_type='search')
        
        사진은 저장하지 않고 menu_matcher로 매칭만 수행
        
        Args:
            image_url: 이미지 URL (presigned URL 또는 일반 URL)
            user_text: 사용자 텍스트 설명 (선택)
        
        Returns:
            매칭된 메뉴 이름 또는 None
        """
        logger.info(f"검색 사진 처리 시작: image_url={image_url[:100] if image_url else None}..., user_text={user_text}")
        
        try:
            # menu_matcher가 단일 진실 소스로 메뉴 매칭 수행
            matched_menu = self.menu_matcher.match_menu(
                image_url=image_url,
                user_text=user_text
            )
            
            if matched_menu:
                logger.info(f"메뉴 매칭 성공: {matched_menu}")
                return matched_menu
            else:
                logger.info("메뉴 매칭 실패")
                return None
                
        except Exception as e:
            logger.error(f"검색 사진 처리 중 오류 발생: {e}", exc_info=True)
            return None
