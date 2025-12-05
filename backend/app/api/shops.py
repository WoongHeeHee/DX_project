"""
가게 관련 API 엔드포인트
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.db.database import get_db
from app.db.models import Shop, Market, ShopMenu, MenuItem, ShopPin
from app.utils.geography import haversine_distance, get_bounding_box
from app.models.schemas import (
    Shop as ShopSchema, 
    ShopWithDistance, 
    NearbyShopsRequest, 
    NearbyShopsResponse,
    MenuItem as MenuItemSchema,
    ShopPinCreate,
    ShopPin as ShopPinSchema,
    BaseResponse
)
from app.api.auth import get_current_user
from app.db.models import User

router = APIRouter()


@router.post("/nearby", response_model=NearbyShopsResponse)
async def get_nearby_shops(
    request: NearbyShopsRequest,
    db: Session = Depends(get_db)
):
    """반경 내 가게 검색 (lat/lng 기반 하버사인 공식 사용)"""
    
    # Bounding box로 먼저 필터링하여 성능 향상
    min_lat, max_lat, min_lng, max_lng = get_bounding_box(
        request.lat, request.lng, request.radius_meters
    )
    
    # 사각형 범위 내 가게 조회
    query = db.query(Shop).filter(
        and_(
            Shop.lat.between(min_lat, max_lat),
            Shop.lng.between(min_lng, max_lng)
        )
    )
    
    # 특정 시장으로 필터링 (선택사항)
    if request.market_id:
        query = query.filter(Shop.market_id == request.market_id)
    
    # 모든 가게 조회 후 정확한 거리 계산 및 필터링
    shops = query.all()
    
    # 하버사인 공식으로 정확한 거리 계산 및 반경 내 필터링
    shops_with_distance = []
    for shop in shops:
        distance = haversine_distance(
            request.lat, request.lng,
            shop.lat, shop.lng
        )
        
        # 반경 내 가게만 포함
        if distance <= request.radius_meters:
            shop_dict = {
                "id": shop.id,
                "market_id": shop.market_id,
                "name": shop.name,
                "name_en": shop.name_en,
                "name_zh": shop.name_zh,
                "name_ja": shop.name_ja,
                "lat": shop.lat,
                "lng": shop.lng,
                "last_reported_open_at": shop.last_reported_open_at,
                "created_at": shop.created_at,
                "distance_meters": round(distance, 2)
            }
            shops_with_distance.append(ShopWithDistance(**shop_dict))
    
    # 거리순 정렬
    shops_with_distance.sort(key=lambda x: x.distance_meters)
    
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


@router.post("/{shop_id}/pin", response_model=BaseResponse)
async def pin_shop(
    shop_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """가게 핀하기 (저장)"""
    try:
        # 가게 존재 확인
        shop = db.query(Shop).filter(Shop.id == shop_id).first()
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="가게를 찾을 수 없습니다"
            )
        
        # 이미 핀했는지 확인
        existing_pin = db.query(ShopPin).filter(
            ShopPin.user_id == current_user.id,
            ShopPin.shop_id == shop_id
        ).first()
        
        if existing_pin:
            return BaseResponse(
                success=True,
                message="이미 핀한 가게입니다"
            )
        
        # 핀 생성
        shop_pin = ShopPin(
            user_id=current_user.id,
            shop_id=shop_id
        )
        
        db.add(shop_pin)
        
        # 이벤트 기록
        from app.db.models import Event, ActionType, TargetType
        event = Event(
            user_id=current_user.id,
            action_type=ActionType.PIN,
            target_type=TargetType.SHOP,
            target_id=shop_id
        )
        db.add(event)
        
        db.commit()
        
        return BaseResponse(
            success=True,
            message="가게가 핀되었습니다"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"핀 추가 실패: {str(e)}"
        )


@router.delete("/{shop_id}/pin", response_model=BaseResponse)
async def unpin_shop(
    shop_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """가게 핀 해제"""
    shop_pin = db.query(ShopPin).filter(
        ShopPin.user_id == current_user.id,
        ShopPin.shop_id == shop_id
    ).first()
    
    if not shop_pin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="핀한 가게를 찾을 수 없습니다"
        )
    
    try:
        db.delete(shop_pin)
        db.commit()
        
        return BaseResponse(
            success=True,
            message="핀이 해제되었습니다"
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"핀 해제 실패: {str(e)}"
        )


@router.get("/my-pins", response_model=List[ShopPinSchema])
async def get_my_pinned_shops(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    market_id: str = None,
    limit: int = 20,
    offset: int = 0
):
    """내가 핀한 가게 목록 조회"""
    query = db.query(ShopPin).filter(
        ShopPin.user_id == current_user.id
    )
    
    # 시장별 필터링 (선택사항)
    if market_id:
        query = query.join(Shop).filter(Shop.market_id == market_id)
    
    shop_pins = query.order_by(ShopPin.created_at.desc()).offset(offset).limit(limit).all()
    
    return shop_pins
