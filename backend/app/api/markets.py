"""
시장 관련 API 엔드포인트
"""

from typing import List, Dict, Any, Optional
from collections import Counter
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import Market, MenuItem, Shop, MarketMenuItem, MarketInfo, KeywordReview, Diary, ShopMenu, Photo
from app.models.schemas import (
    Market as MarketSchema,
    MenuItem as MenuItemSchema,
    MarketStats,
    MarketInfo as MarketInfoSchema,
    MarketInfoCreate,
)

router = APIRouter()


@router.get("/", response_model=List[MarketSchema])
async def get_markets(db: Session = Depends(get_db)):
    """모든 시장 목록 조회"""
    markets = db.query(Market).all()
    return markets


@router.get("/{market_id}", response_model=MarketSchema)
async def get_market(market_id: str, db: Session = Depends(get_db)):
    """특정 시장 정보 조회"""
    market = db.query(Market).filter(Market.id == market_id).first()
    if not market:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="시장을 찾을 수 없습니다"
        )
    return market


@router.get("/{market_id}/menu-items", response_model=List[MenuItemSchema])
async def get_market_menu_items(market_id: str, db: Session = Depends(get_db)):
    """시장의 메뉴 아이템 목록 조회"""
    market = db.query(Market).filter(Market.id == market_id).first()
    if not market:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="시장을 찾을 수 없습니다"
        )
    
    # MarketMenuItem 조인 테이블을 통해 조회
    menu_items = db.query(MenuItem).join(MarketMenuItem).filter(
        MarketMenuItem.market_id == market_id
    ).all()
    return menu_items


@router.get("/{market_id}/stats", response_model=MarketStats)
async def get_market_stats(market_id: str, db: Session = Depends(get_db)):
    """시장 통계 정보 조회"""
    market = db.query(Market).filter(Market.id == market_id).first()
    if not market:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="시장을 찾을 수 없습니다"
        )
    
    # 가게 수
    total_shops = db.query(Shop).filter(Shop.market_id == market_id).count()
    
    # 메뉴 아이템 수 (MarketMenuItem 조인 테이블을 통해 조회)
    total_menu_items = db.query(MarketMenuItem).filter(
        MarketMenuItem.market_id == market_id
    ).count()
    
    # 최근 사진 수 (24시간 내)
    from datetime import datetime, timedelta
    from app.db.models import Photo
    yesterday = datetime.utcnow() - timedelta(days=1)
    recent_photos_count = db.query(Photo).filter(Photo.created_at >= yesterday).count()
    
    # 인기 키워드 (키워드 리뷰에서)
    from app.db.models import KeywordReview
    popular_keywords_query = db.query(KeywordReview).filter(
        KeywordReview.market_id == market_id
    ).order_by(KeywordReview.count.desc()).limit(10).all()
    
    popular_keywords = [
        {"keyword": kr.keyword, "count": kr.count}
        for kr in popular_keywords_query
    ]
    
    return MarketStats(
        total_shops=total_shops,
        total_menu_items=total_menu_items,
        recent_photos_count=recent_photos_count,
        popular_keywords=popular_keywords
    )


@router.get("/{market_id}/info", response_model=MarketInfoSchema)
async def get_market_info(market_id: str, db: Session = Depends(get_db)):
    """시장 부가정보 조회 (주소, 교통, 주차, 화장실 등)"""
    try:
        market = db.query(Market).filter(Market.id == market_id).first()
        if not market:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시장을 찾을 수 없습니다"
            )
        
        market_info = db.query(MarketInfo).filter(MarketInfo.market_id == market_id).first()
        if not market_info:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시장 부가정보를 찾을 수 없습니다"
            )
        
        # FastAPI가 자동으로 변환하도록 반환
        # 변환 실패 시를 대비해 에러 핸들링 추가
        try:
            return market_info
        except Exception as e:
            # 변환 실패 시 상세 정보 로깅
            import traceback
            error_msg = f"MarketInfo 스키마 변환 실패 (market_id: {market_id})"
            print(error_msg)
            print(f"에러: {str(e)}")
            print(f"상세: {traceback.format_exc()}")
            
            # 주요 필드 확인
            debug_info = {
                "market_info_id": getattr(market_info, 'market_info_id', None),
                "market_id": getattr(market_info, 'market_id', None),
                "address": getattr(market_info, 'address', None),
                "created_at": str(getattr(market_info, 'created_at', None)),
                "created_at_type": str(type(getattr(market_info, 'created_at', None))),
            }
            print(f"디버그 정보: {debug_info}")
            
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"시장 부가정보 변환 중 오류가 발생했습니다: {str(e)}"
            )
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_msg = f"get_market_info 예외 발생 (market_id: {market_id})"
        print(error_msg)
        print(f"에러: {str(e)}")
        print(f"상세: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"시장 부가정보 조회 중 오류가 발생했습니다: {str(e)}"
        )


@router.post("/{market_id}/info", response_model=MarketInfoSchema)
async def create_market_info(
    market_id: str,
    market_info_data: MarketInfoCreate,
    db: Session = Depends(get_db)
):
    """시장 부가정보 생성"""
    market = db.query(Market).filter(Market.id == market_id).first()
    if not market:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="시장을 찾을 수 없습니다"
        )
    
    # 이미 부가정보가 있는지 확인
    existing_info = db.query(MarketInfo).filter(MarketInfo.market_id == market_id).first()
    if existing_info:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 부가정보가 존재합니다. PUT 메서드를 사용하여 업데이트하세요."
        )
    
    market_info = MarketInfo(
        market_id=market_id,
        **market_info_data.model_dump(exclude={"market_id"})
    )
    db.add(market_info)
    db.commit()
    db.refresh(market_info)
    
    return market_info


@router.put("/{market_id}/info", response_model=MarketInfoSchema)
async def update_market_info(
    market_id: str,
    market_info_data: MarketInfoCreate,
    db: Session = Depends(get_db)
):
    """시장 부가정보 업데이트"""
    market = db.query(Market).filter(Market.id == market_id).first()
    if not market:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="시장을 찾을 수 없습니다"
        )
    
    market_info = db.query(MarketInfo).filter(MarketInfo.market_id == market_id).first()
    if not market_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="시장 부가정보를 찾을 수 없습니다"
        )
    
    # 업데이트
    for key, value in market_info_data.model_dump(exclude={"market_id"}).items():
        setattr(market_info, key, value)
    
    db.commit()
    db.refresh(market_info)
    
    return market_info


@router.get("/{market_id}/status")
async def get_market_status(market_id: str, db: Session = Depends(get_db)) -> Dict[str, Any]:
    """시장 상태 조회: 상태(green/yellow/red) 및 기본 카운트"""
    market = db.query(Market).filter(Market.id == market_id).first()
    if not market:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="시장을 찾을 수 없습니다"
        )

    total_shops = db.query(Shop).filter(Shop.market_id == market_id).count()
    # 간단한 기준: 데이터 미존재 시 green으로 처리
    open_shops = total_shops  # 실제 로직 연결 시 교체
    closed_shops = 0
    suspicious_shops = 0

    status_value = "green"
    if total_shops > 0:
        open_rate = open_shops / total_shops
        if open_rate < 0.2:
            status_value = "red"
        elif open_rate < 0.7:
            status_value = "yellow"
    else:
        status_value = "red"

    return {
        "status": status_value,
        "total_shops": total_shops,
        "open_shops": open_shops,
        "suspicious_shops": suspicious_shops,
        "closed_shops": closed_shops,
    }


@router.get("/{market_id}/top-keywords")
async def get_market_top_keywords(market_id: str, db: Session = Depends(get_db)) -> List[Dict[str, Any]]:
    """시장 인기 키워드 상위 10개 반환 (KeywordReview 우선, 없으면 Diary keywords 집계)"""
    market = db.query(Market).filter(Market.id == market_id).first()
    if not market:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="시장을 찾을 수 없습니다"
        )

    keywords: List[Dict[str, Any]] = []

    kr_list = db.query(KeywordReview).filter(KeywordReview.market_id == market_id).order_by(
        KeywordReview.count.desc()
    ).limit(10).all()

    if kr_list:
        keywords = [{"keyword": kr.keyword, "count": kr.count} for kr in kr_list]
    else:
        diary_keywords: Counter = Counter()
        diaries = db.query(Diary).filter(Diary.market_id == market_id).all()
        for diary in diaries:
            if diary.keywords:
                if isinstance(diary.keywords, list):
                    diary_keywords.update(diary.keywords)
                elif isinstance(diary.keywords, dict):
                    diary_keywords.update(diary.keywords.keys())
        keywords = [
            {"keyword": kw, "count": cnt} for kw, cnt in diary_keywords.most_common(10)
        ]

    return keywords


@router.get("/{market_id}/shops/by-menu")
async def get_shops_by_menu(
    market_id: str,
    menu_name: str = Query(..., description="메뉴 이름 (한국어)"),
    lat: Optional[float] = Query(None, description="현재 위치 위도 (거리 계산용)"),
    lng: Optional[float] = Query(None, description="현재 위치 경도 (거리 계산용)"),
    db: Session = Depends(get_db)
):
    """
    시장의 특정 메뉴를 판매하는 가게 목록 조회
    
    Args:
        market_id: 시장 ID
        menu_name: 메뉴 이름 (한국어)
        lat: 현재 위치 위도 (거리 계산용, 선택사항)
        lng: 현재 위치 경도 (거리 계산용, 선택사항)
    
    Returns:
        가게 목록 (영업 상태, 거리 기준 정렬)
    """
    try:
        # 시장 존재 확인
        market = db.query(Market).filter(Market.id == market_id).first()
        if not market:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시장을 찾을 수 없습니다"
            )
        
        # 메뉴 아이템 조회 (이름으로)
        menu_item = db.query(MenuItem).filter(MenuItem.name == menu_name).first()
        if not menu_item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="메뉴를 찾을 수 없습니다"
            )
        
        # 해당 메뉴를 판매하는 가게 조회 (ShopMenu 조인)
        shops_query = db.query(Shop).join(ShopMenu).filter(
            Shop.market_id == market_id,
            ShopMenu.menu_item_id == menu_item.id,
            ShopMenu.available == True
        )
        
        shops = shops_query.all()
        
        # 현재 시간 (한국 시간대 기준)
        korea_tz = ZoneInfo("Asia/Seoul")
        current_time = datetime.now(korea_tz)
        current_hour = current_time.hour
        current_minute = current_time.minute
        current_time_minutes = current_hour * 60 + current_minute
        
        # 영업 상태 계산 및 가게 이미지 조회
        from app.api.market_photos import calculate_shop_status
        
        # CDN URL 생성 헬퍼 함수
        def s3_key_to_cdn_url(s3_key: str) -> str:
            """S3 key를 CDN URL로 변환"""
            if not s3_key:
                return ""
            cdn_base_url = "https://dnzeuzpu74ulj.cloudfront.net"
            if s3_key.startswith('http://') or s3_key.startswith('https://'):
                return s3_key
            return f"{cdn_base_url}/{s3_key}"
        
        def placeholder_image(name: str, menu_id: str, variant: int = 1) -> str:
            """메뉴 placeholder 이미지 URL 생성"""
            from urllib.parse import quote
            encoded_name = quote(name)
            clamped = max(1, min(3, variant))
            return f"https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/{encoded_name}/{encoded_name}{clamped}_{menu_id}.png"
        
        result = []
        for shop in shops:
            # 영업 상태 계산
            status_color = calculate_shop_status(shop, current_time, current_time_minutes, db)
            
            # 가게 이미지 조회 (해당 가게의 해당 메뉴 사진, 최대 3개)
            photos = db.query(Photo).filter(
                Photo.shop_id == shop.id,
                Photo.menu_item_id == menu_item.id,
                Photo.processed == True
            ).order_by(Photo.taken_at.desc()).limit(3).all()
            
            image_urls = []
            if photos:
                for photo in photos:
                    image_url = s3_key_to_cdn_url(photo.thumbnail_s3_key or photo.s3_key)
                    image_urls.append(image_url)
            else:
                # 이미지가 없으면 메뉴 placeholder 사용
                placeholder_url = placeholder_image(menu_item.name, menu_item.id, variant=1)
                image_urls.append(placeholder_url)
            
            # 거리 계산 (lat, lng가 제공된 경우)
            distance_meters = None
            if lat is not None and lng is not None:
                from app.utils.geography import haversine_distance
                distance_meters = haversine_distance(lat, lng, shop.lat, shop.lng)
            
            shop_dict = {
                "id": str(shop.id),
                "name": shop.name,
                "name_en": shop.name_en,
                "name_zh": shop.name_zh,
                "name_ja": shop.name_ja,
                "lat": shop.lat,
                "lng": shop.lng,
                "image_urls": image_urls,
                "status": status_color,  # "green", "yellow", "red"
                "distance_meters": distance_meters,
                "open_time": shop.open_time,
                "close_time": shop.close_time,
                "closed_days": shop.closed_days,
            }
            result.append(shop_dict)
        
        # 정렬: 영업상태(녹>황>적) > 거리
        def sort_key(shop_dict):
            status_order = {"green": 0, "yellow": 1, "red": 2}
            status_priority = status_order.get(shop_dict["status"], 3)
            distance = shop_dict["distance_meters"] if shop_dict["distance_meters"] is not None else float('inf')
            return (status_priority, distance)
        
        result.sort(key=sort_key)
        
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
            detail=f"가게 목록 조회 실패: {str(e)}"
        )