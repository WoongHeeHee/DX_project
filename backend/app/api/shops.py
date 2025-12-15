"""
가게 관련 API 엔드포인트
"""

from typing import List, Optional
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from fastapi import APIRouter, Depends, HTTPException, status, Query
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


@router.get("/my-pins")
async def get_my_pinned_shops(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    market_id: Optional[str] = Query(None, description="시장 ID로 필터링"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0)
):
    """내가 핀한 가게 목록 조회 (Shop 정보 및 영업 상태 포함)"""
    try:
        from sqlalchemy.orm import joinedload
        from app.api.market_photos import calculate_shop_status
        
        print(f"[get_my_pinned_shops] user_id: {current_user.id}, market_id: {market_id}")
        
        query = db.query(ShopPin).options(joinedload(ShopPin.shop)).filter(
            ShopPin.user_id == current_user.id
        )
        
        # 시장별 필터링 (선택사항)
        if market_id:
            query = query.join(Shop).filter(Shop.market_id == market_id)
            print(f"[get_my_pinned_shops] market_id 필터링 적용: {market_id}")
        
        shop_pins = query.order_by(ShopPin.created_at.desc()).offset(offset).limit(limit).all()
        
        print(f"[get_my_pinned_shops] found {len(shop_pins)} shop_pins")
        
        # 각 shop_pin의 shop 정보 로깅
        for i, shop_pin in enumerate(shop_pins):
            shop = shop_pin.shop
            if shop:
                print(f"[get_my_pinned_shops] shop_pin[{i}]: shop_id={shop.id}, shop_name={shop.name}, shop.market_id={shop.market_id}")
            else:
                print(f"[get_my_pinned_shops] shop_pin[{i}]: shop이 None임")
        
        # 현재 시간 (한국 시간대 기준)
        korea_tz = ZoneInfo("Asia/Seoul")
        current_time = datetime.now(korea_tz)
        current_hour = current_time.hour
        current_minute = current_time.minute
        current_time_minutes = current_hour * 60 + current_minute
        
        # CDN URL 생성 헬퍼 함수
        def s3_key_to_cdn_url(s3_key: str) -> str:
            """S3 key를 CDN URL로 변환"""
            if not s3_key:
                return ""
            cdn_base_url = "https://dnzeuzpu74ulj.cloudfront.net"
            if s3_key.startswith('http://') or s3_key.startswith('https://'):
                return s3_key
            return f"{cdn_base_url}/{s3_key}"
        
        # Shop 정보를 포함한 응답 생성
        result = []
        for shop_pin in shop_pins:
            shop = shop_pin.shop
            if not shop:
                print(f"[get_my_pinned_shops] shop_pin.id={shop_pin.id}에 shop이 없음, 스킵")
                continue  # Shop이 없으면 스킵
            
            try:
                # 영업 상태 계산
                status_color = calculate_shop_status(shop, current_time, current_time_minutes, db)
                
                # 가게 이미지 조회 (해당 가게의 모든 사진, 최대 3개)
                from app.db.models import Photo
                photos = db.query(Photo).filter(
                    Photo.shop_id == shop.id,
                    Photo.processed == True
                ).order_by(Photo.taken_at.desc()).limit(3).all()
                
                image_urls = []
                if photos:
                    for photo in photos:
                        image_url = s3_key_to_cdn_url(photo.thumbnail_s3_key or photo.s3_key)
                        image_urls.append(image_url)
                else:
                    # 이미지가 없으면 대표 이미지 사용
                    if shop.rep_image_url:
                        image_urls.append(s3_key_to_cdn_url(shop.rep_image_url))
                
                shop_dict = {
                    "id": str(shop.id),
                    "name": shop.name,
                    "name_en": shop.name_en,
                    "name_zh": shop.name_zh,
                    "name_ja": shop.name_ja,
                    "market_id": str(shop.market_id),  # market_id 추가
                    "lat": shop.lat,
                    "lng": shop.lng,
                    "address": None,  # Shop 모델에 address 필드가 없음
                    "rep_image_url": shop.rep_image_url,
                    "open_time": shop.open_time,
                    "close_time": shop.close_time,
                    "closed_days": shop.closed_days,
                    "average_price": None,  # Shop 모델에 average_price 필드가 없음
                    "status": status_color,  # "green", "yellow", "red"
                    "image_urls": image_urls,  # 실시간 사진 URL 리스트 (최대 3개)
                }
                print(f"[get_my_pinned_shops] shop_dict 추가: id={shop_dict['id']}, name={shop_dict['name']}, market_id={shop_dict['market_id']}, image_urls 개수={len(image_urls)}")
                result.append(shop_dict)
            except Exception as e:
                print(f"[get_my_pinned_shops] shop.id={shop.id} 처리 중 에러: {str(e)}")
                import traceback
                print(traceback.format_exc())
                # 개별 shop 처리 에러는 무시하고 계속 진행
                continue
        
        print(f"[get_my_pinned_shops] 최종 결과: {len(result)}개 shop 반환")
        return result
        
    except Exception as e:
        import traceback
        error_traceback = traceback.format_exc()
        print(f"[get_my_pinned_shops] 에러 발생: {str(e)}")
        print(f"[get_my_pinned_shops] 스택 트레이스:\n{error_traceback}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"핀한 가게 목록 조회 실패: {str(e)}"
        )


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

