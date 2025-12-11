"""
지리 좌표 관련 유틸리티 함수
가장 가까운 shop 찾기
"""

import logging
from typing import Optional
from sqlalchemy.orm import Session

from app.db.models import Shop
from app.utils.geography import haversine_distance, get_bounding_box

logger = logging.getLogger(__name__)


def find_nearest_shop(
    db: Session,
    lat: float,
    lng: float,
    max_distance_meters: float = 10000
) -> Optional[str]:
    """
    GPS 좌표 기준으로 가장 가까운 가게를 찾아 shop_id를 반환
    
    Args:
        db: 데이터베이스 세션
        lat: 위도
        lng: 경도
        max_distance_meters: 최대 검색 거리 (미터, 기본값 10km)
    
    Returns:
        가장 가까운 가게의 shop_id (str) 또는 None
    """
    try:
        # Bounding box로 먼저 필터링하여 성능 향상
        min_lat, max_lat, min_lng, max_lng = get_bounding_box(
            lat, lng, max_distance_meters
        )
        
        # 사각형 범위 내 가게 조회
        shops = db.query(Shop).filter(
            Shop.lat.between(min_lat, max_lat),
            Shop.lng.between(min_lng, max_lng)
        ).all()
        
        if not shops:
            logger.info(f"근처 가게를 찾을 수 없음: lat={lat}, lng={lng}")
            return None
        
        # 하버사인 공식으로 정확한 거리 계산
        closest_shop = None
        min_distance = float('inf')
        
        for shop in shops:
            distance = haversine_distance(lat, lng, shop.lat, shop.lng)
            
            if distance < min_distance:
                min_distance = distance
                closest_shop = shop
        
        if closest_shop:
            logger.info(f"가장 가까운 가게 찾음: shop_id={closest_shop.id}, distance={min_distance:.2f}m")
            return str(closest_shop.id)
        else:
            logger.info(f"가장 가까운 가게를 찾을 수 없음")
            return None
            
    except Exception as e:
        logger.error(f"가장 가까운 가게 찾기 중 오류 발생: {e}", exc_info=True)
        return None

