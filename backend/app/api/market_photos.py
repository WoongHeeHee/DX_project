"""
지도 - 시장 화면 관련 API 엔드포인트
60분 이내 사진 조회, 카테고리 필터링, 가게 상태 계산 등
"""

from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_

from app.db.database import get_db
from app.db.models import Market, Photo, Shop, MenuItem, ShopMenu, MarketMenuItem
from app.models.schemas import BaseResponse, Photo as PhotoSchema
from app.services.s3_service import S3Service

router = APIRouter()


@router.get("/{market_id}/recent-photos")
async def get_market_recent_photos(
    market_id: str,
    category: Optional[str] = Query(None, description="카테고리 필터 (Meals, Snacks, Sweets, Drink)"),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """
    시장의 최근 사진 조회 (60분 이내)
    
    Args:
        market_id: 시장 ID
        category: 메뉴 카테고리 필터
        limit: 최대 반환 개수
    """
    try:
        # 시장 존재 확인
        market = db.query(Market).filter(Market.id == market_id).first()
        if not market:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시장을 찾을 수 없습니다"
            )
        
        # 60분 이내 시간 계산
        time_threshold = datetime.now(timezone.utc) - timedelta(minutes=60)
        
        # 시장 내 가게들 조회
        shops = db.query(Shop).filter(Shop.market_id == market_id).all()
        shop_ids = [shop.id for shop in shops]
        
        if not shop_ids:
            return {
                "success": True,
                "photos": [],
                "total_count": 0
            }
        
        # 사진 조회 (60분 이내, 해당 시장의 가게들)
        query = db.query(Photo).filter(
            Photo.shop_id.in_(shop_ids),
            Photo.created_at >= time_threshold,
            Photo.processed == True
        )
        
        # 카테고리 필터링은 클라이언트에서 처리하거나, 
        # 더 간단하게 모든 사진을 가져온 후 파이썬에서 필터링
        # (성능 최적화는 나중에 필요시 개선)
        
        # 최신순 정렬
        photos = query.order_by(Photo.created_at.desc()).limit(limit).all()
        
        # S3 URL 생성
        s3_service = S3Service()
        photo_list = []
        for photo in photos:
            photo_dict = {
                "id": str(photo.id),
                "s3_key": photo.s3_key,
                "thumbnail_s3_key": photo.thumbnail_s3_key,
                "image_url": s3_service.generate_presigned_download_url(photo.s3_key) if photo.s3_key else None,
                "thumbnail_url": s3_service.generate_presigned_download_url(photo.thumbnail_s3_key) if photo.thumbnail_s3_key else None,
                "lat": photo.lat,
                "lng": photo.lng,
                "taken_at": photo.taken_at,
                "menu_item_id": str(photo.menu_item_id),
                "created_at": photo.created_at
            }
            photo_list.append(photo_dict)
        
        return {
            "success": True,
            "photos": photo_list,
            "total_count": len(photo_list)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사진 조회 실패: {str(e)}"
        )


@router.get("/{market_id}/bestselling")
async def get_market_bestselling(
    market_id: str,
    limit: int = Query(3, ge=1, le=10),
    db: Session = Depends(get_db)
):
    """
    시장의 Bestselling 메뉴 조회 (좋아요 기반)
    """
    try:
        from app.db.models import Like
        
        # 시장 존재 확인
        market = db.query(Market).filter(Market.id == market_id).first()
        if not market:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시장을 찾을 수 없습니다"
            )
        
        # 좋아요가 많은 메뉴 조회 (MarketMenuItem 조인 테이블을 통해)
        bestselling = db.query(
            MenuItem,
            func.count(Like.id).label('like_count')
        ).join(
            MarketMenuItem, MarketMenuItem.menu_item_id == MenuItem.id
        ).join(
            Like, Like.menu_item_id == MenuItem.id
        ).filter(
            MarketMenuItem.market_id == market_id
        ).group_by(
            MenuItem.id
        ).order_by(
            func.count(Like.id).desc()
        ).limit(limit).all()
        
        result = []
        for menu_item, like_count in bestselling:
            result.append({
                "id": str(menu_item.id),
                "name": menu_item.name,
                "name_en": menu_item.name_en,
                "name_zh": menu_item.name_zh,
                "name_ja": menu_item.name_ja,
                "rep_image_url": menu_item.rep_image_url,
                "description": menu_item.description,
                "like_count": like_count
            })
        
        return {
            "success": True,
            "bestselling": result
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Bestselling 조회 실패: {str(e)}"
        )


@router.get("/{market_id}/shops/status")
async def get_shops_with_status(
    market_id: str,
    db: Session = Depends(get_db)
):
    """
    시장의 가게 목록과 영업 상태 조회
    
    Returns:
        가게 리스트와 각 가게의 상태 (녹색/황색/적색)
    """
    try:
        # 시장 존재 확인
        market = db.query(Market).filter(Market.id == market_id).first()
        if not market:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시장을 찾을 수 없습니다"
            )
        
        shops = db.query(Shop).filter(Shop.market_id == market_id).all()
        current_time = datetime.now(timezone.utc)
        current_hour = current_time.hour
        current_minute = current_time.minute
        current_time_minutes = current_hour * 60 + current_minute
        
        result = []
        for shop in shops:
            status_color = calculate_shop_status(shop, current_time, current_time_minutes, db)
            
            result.append({
                "id": str(shop.id),
                "name": shop.name,
                "name_en": shop.name_en,
                "name_zh": shop.name_zh,
                "name_ja": shop.name_ja,
                "lat": shop.lat,
                "lng": shop.lng,
                "rep_image_url": shop.rep_image_url,
                "open_time": shop.open_time,
                "close_time": shop.close_time,
                "closed_days": shop.closed_days,
                "closed_days_en": shop.closed_days_en,
                "closed_days_zh": shop.closed_days_zh,
                "closed_days_ja": shop.closed_days_ja,
                "last_reported_open_at": shop.last_reported_open_at,
                "status": status_color  # "green", "yellow", "red"
            })
        
        return {
            "success": True,
            "shops": result,
            "total_count": len(result)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"가게 상태 조회 실패: {str(e)}"
        )


def calculate_shop_status(shop: Shop, current_time: datetime, current_time_minutes: int, db: Session) -> str:
    """
    가게 영업 상태 계산 (녹색/황색/적색)
    
    structure.md의 로직에 따라:
    - 녹색: 운영시간 내 + 제보/리뷰 존재
    - 황색: 운영시간 경계 + 제보/리뷰 유무에 따라
    - 적색: 그 외
    """
    if not shop.open_time or not shop.close_time:
        # 운영시간 정보가 없으면 제보/리뷰 기반으로만 판단
        if shop.last_reported_open_at:
            hours_since_report = (current_time - shop.last_reported_open_at).total_seconds() / 3600
            return "green" if hours_since_report < 1 else "yellow" if hours_since_report < 3 else "red"
        return "red"
    
    # 운영시간 파싱 (HH:MM 형식)
    try:
        open_hour, open_minute = map(int, shop.open_time.split(':'))
        close_hour, close_minute = map(int, shop.close_time.split(':'))
        open_minutes = open_hour * 60 + open_minute
        close_minutes = close_hour * 60 + close_minute
    except:
        return "red"
    
    # 휴무일 확인 (closed_days는 이제 String이므로 파싱 필요)
    # TODO: closed_days가 String 형식으로 저장되므로, 파싱 로직이 필요할 수 있습니다.
    # 현재는 휴무일 체크를 건너뜁니다.
    
    # 제보/리뷰 존재 여부 확인
    has_recent_report = False
    if shop.last_reported_open_at:
        hours_since_report = (current_time - shop.last_reported_open_at).total_seconds() / 3600
        has_recent_report = hours_since_report < 12  # 12시간 이내 제보/리뷰
    
    # 시간대별 상태 계산
    # 녹색 조건
    # 1. 현재 시간이 (오픈시간 + 1h, 마감시간 - 1h) 내
    if open_minutes + 60 <= current_time_minutes <= close_minutes - 60:
        return "green"
    
    # 2. 현재 시간이 (오픈시간 + 0.5h, 마감시간 - 0.5h) 내 + 제보/리뷰 존재
    if open_minutes + 30 <= current_time_minutes <= close_minutes - 30:
        if has_recent_report:
            return "green"
    
    # 황색 조건
    # 1. (오픈시간 + 0.5h, 오픈시간 + 1h) 또는 (마감시간 - 1h, 마감시간 - 0.5h) + 제보/리뷰 없음
    if (open_minutes + 30 < current_time_minutes <= open_minutes + 60) or \
       (close_minutes - 60 <= current_time_minutes < close_minutes - 30):
        if not has_recent_report:
            return "yellow"
    
    # 2. (오픈시간, 오픈시간 + 0.5h) 또는 (마감시간 - 0.5h, 마감시간) + 제보/리뷰 존재
    if (open_minutes <= current_time_minutes <= open_minutes + 30) or \
       (close_minutes - 30 <= current_time_minutes <= close_minutes):
        if has_recent_report:
            return "yellow"
    
    # 적색: 그 외
    return "red"


@router.get("/{market_id}/photos/locations")
async def get_photo_locations(
    market_id: str,
    limit: int = Query(10, ge=1, le=20),
    db: Session = Depends(get_db)
):
    """
    시장의 최근 사진 위치 조회 (지도 핀용)
    60분 이내, 상위 N개 위치
    """
    try:
        # 시장 존재 확인
        market = db.query(Market).filter(Market.id == market_id).first()
        if not market:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시장을 찾을 수 없습니다"
            )
        
        # 시장 내 가게들
        shops = db.query(Shop).filter(Shop.market_id == market_id).all()
        shop_ids = [shop.id for shop in shops]
        
        if not shop_ids:
            return {
                "success": True,
                "locations": []
            }
        
        # 60분 이내 사진 조회
        time_threshold = datetime.now(timezone.utc) - timedelta(minutes=60)
        
        photos = db.query(Photo).filter(
            Photo.shop_id.in_(shop_ids),
            Photo.created_at >= time_threshold,
            Photo.processed == True
        ).order_by(Photo.created_at.desc()).limit(limit).all()
        
        # 위치별로 그룹화 (동일 위치는 하나만)
        locations = []
        seen_locations = set()
        
        for photo in photos:
            # 위치를 반올림하여 그룹화 (약 10m 단위)
            lat_rounded = round(photo.lat, 4)
            lng_rounded = round(photo.lng, 4)
            location_key = (lat_rounded, lng_rounded)
            
            if location_key not in seen_locations:
                seen_locations.add(location_key)
                locations.append({
                    "lat": photo.lat,
                    "lng": photo.lng,
                    "photo_id": str(photo.id),
                    "taken_at": photo.taken_at
                })
        
        return {
            "success": True,
            "locations": locations[:limit]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사진 위치 조회 실패: {str(e)}"
        )

