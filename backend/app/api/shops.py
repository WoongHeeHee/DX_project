"""
가게 관련 API 엔드포인트
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, text

from app.db.database import get_db
from app.db.models import Shop, Market, ShopMenu, MenuItem
from app.models.schemas import (
    Shop as ShopSchema, 
    ShopWithDistance, 
    NearbyShopsRequest, 
    NearbyShopsResponse,
    MenuItem as MenuItemSchema
)

router = APIRouter()


@router.post("/nearby", response_model=NearbyShopsResponse)
async def get_nearby_shops(
    request: NearbyShopsRequest,
    db: Session = Depends(get_db)
):
    """반경 내 가게 검색 (PostGIS 사용)"""
    
    # PostGIS ST_DWithin을 사용한 반경 검색
    query = db.query(
        Shop,
        func.ST_Distance(
            Shop.geom,
            func.ST_GeogFromText(f'POINT({request.lng} {request.lat})')
        ).label('distance')
    ).filter(
        func.ST_DWithin(
            Shop.geom,
            func.ST_GeogFromText(f'POINT({request.lng} {request.lat})'),
            request.radius_meters
        )
    )
    
    # 특정 시장으로 필터링 (선택사항)
    if request.market_id:
        query = query.filter(Shop.market_id == request.market_id)
    
    # 거리순 정렬
    results = query.order_by(text('distance')).all()
    
    # 응답 데이터 구성
    shops_with_distance = []
    for shop, distance in results:
        shop_dict = {
            "id": shop.id,
            "market_id": shop.market_id,
            "name": shop.name,
            "name_en": shop.name_en,
            "name_zh": shop.name_zh,
            "name_ja": shop.name_ja,
            "lat": shop.lat,
            "lng": shop.lng,
            "address": shop.address,
            "last_reported_open_at": shop.last_reported_open_at,
            "created_at": shop.created_at,
            "distance_meters": round(distance, 2)
        }
        shops_with_distance.append(ShopWithDistance(**shop_dict))
    
    return NearbyShopsResponse(
        success=True,
        shops=shops_with_distance,
        total_count=len(shops_with_distance)
    )


@router.get("/{shop_id}", response_model=ShopSchema)
async def get_shop(shop_id: str, db: Session = Depends(get_db)):
    """특정 가게 정보 조회"""
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="가게를 찾을 수 없습니다"
        )
    return shop


@router.get("/{shop_id}/menu", response_model=List[MenuItemSchema])
async def get_shop_menu(shop_id: str, db: Session = Depends(get_db)):
    """가게의 메뉴 조회"""
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="가게를 찾을 수 없습니다"
        )
    
    # 가게의 메뉴 아이템들을 조회
    menu_items = db.query(MenuItem).join(ShopMenu).filter(
        ShopMenu.shop_id == shop_id,
        ShopMenu.available == True
    ).all()
    
    return menu_items


@router.put("/{shop_id}/report-open")
async def report_shop_open(shop_id: str, db: Session = Depends(get_db)):
    """가게 영업 상태 보고 (사진 업로드 시 호출)"""
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="가게를 찾을 수 없습니다"
        )
    
    from datetime import datetime
    shop.last_reported_open_at = datetime.utcnow()
    db.commit()
    
    return {"success": True, "message": "가게 영업 상태가 업데이트되었습니다"}


@router.get("/", response_model=List[ShopSchema])
async def get_shops(
    market_id: str = None,
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """가게 목록 조회"""
    query = db.query(Shop)
    
    if market_id:
        query = query.filter(Shop.market_id == market_id)
    
    shops = query.offset(offset).limit(limit).all()
    return shops
