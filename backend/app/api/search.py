"""
검색 관련 API 엔드포인트
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import MenuItem, Shop, ShopMenu, MarketMenuItem
from app.models.schemas import (
    ImageSearchRequest, 
    ImageSearchResponse, 
    SearchResult,
    MenuItem as MenuItemSchema,
    ShopWithDistance
)
from app.services.openai_service import OpenAIService
from app.services.pinecone_service import PineconeService
from app.services.menu_matcher_service import MenuMatcherService
from app.api.shops import get_nearby_shops
from app.models.schemas import NearbyShopsRequest

router = APIRouter()


@router.post("/image", response_model=ImageSearchResponse)
async def search_by_image(
    request: ImageSearchRequest,
    db: Session = Depends(get_db)
):
    """
    이미지/텍스트/이미지+텍스트로 음식 검색
    menu_matcher의 match_menu() 활용
    """
    try:
        # 이미지와 텍스트 모두 없는 경우
        if not request.image_url and not request.user_text:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미지 URL 또는 텍스트 설명 중 하나는 필수입니다"
            )
        
        # menu_matcher 서비스 사용
        menu_matcher = MenuMatcherService(db)
        
        # 메뉴 매칭 (이미지+텍스트 모두 활용)
        matched_menu_name = menu_matcher.match_menu(
            image_url=request.image_url,
            user_text=request.user_text
        )
        
        if not matched_menu_name:
            return ImageSearchResponse(
                success=True,
                results=[],
                message="메뉴를 찾을 수 없습니다. 다른 사진/텍스트를 입력해주세요"
            )
        
        # 매칭된 메뉴 아이템 조회
        menu_item = db.query(MenuItem).filter(MenuItem.name == matched_menu_name).first()
        
        if not menu_item:
            return ImageSearchResponse(
                success=True,
                results=[],
                message="메뉴를 찾을 수 없습니다"
            )
        
        # 근처 가게 검색 (위치 정보가 있는 경우)
        shops_nearby = []
        if request.lat is not None and request.lng is not None:
            # 해당 메뉴를 판매하는 가게 조회
            shops_with_menu = db.query(Shop).join(ShopMenu).filter(
                ShopMenu.menu_item_id == menu_item.id,
                ShopMenu.available == True
            ).all()
            
            # 하버사인 공식으로 거리 계산
            from app.utils.geography import haversine_distance
            for shop in shops_with_menu[:5]:  # 최대 5개
                distance = haversine_distance(
                    request.lat, request.lng,
                    shop.lat, shop.lng
                )
                
                shops_nearby.append(ShopWithDistance(
                    id=shop.id,
                    market_id=shop.market_id,
                    name=shop.name,
                    name_en=shop.name_en,
                    name_zh=shop.name_zh,
                    name_ja=shop.name_ja,
                    lat=shop.lat,
                    lng=shop.lng,
                    last_reported_open_at=shop.last_reported_open_at,
                    created_at=shop.created_at,
                    distance_meters=round(distance, 2)
                ))
            
            # 거리순 정렬
            shops_nearby.sort(key=lambda x: x.distance_meters)
        
        # 가장 가까운 가게가 속한 시장 찾기
        nearest_market_id = None
        if shops_nearby:
            nearest_shop = shops_nearby[0]
            nearest_market_id = nearest_shop.market_id
        
        results = [SearchResult(
            menu_item=MenuItemSchema.model_validate(menu_item),
            confidence=1.0,  # menu_matcher는 boolean 결과이므로 confidence는 1.0
            shops_nearby=shops_nearby
        )]
        
        return ImageSearchResponse(
            success=True,
            results=results,
            message=f"'{matched_menu_name}' 메뉴를 찾았습니다"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"검색 중 오류가 발생했습니다: {str(e)}"
        )


@router.get("/menu-items", response_model=List[MenuItemSchema])
async def search_menu_items(
    q: str = "",
    market_id: str = None,
    spice_level_max: int = 5,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """메뉴 아이템 텍스트 검색"""
    query = db.query(MenuItem)
    
    # 텍스트 검색 (이름으로)
    if q:
        query = query.filter(
            MenuItem.name.ilike(f"%{q}%") |
            MenuItem.name_en.ilike(f"%{q}%") |
            MenuItem.description.ilike(f"%{q}%")
        )
    
    # 시장 필터 (MarketMenuItem 조인 테이블을 통해)
    if market_id:
        query = query.join(MarketMenuItem).filter(MarketMenuItem.market_id == market_id)
    
    # 매운맛 수준 필터
    query = query.filter(MenuItem.spice_level <= spice_level_max)
    
    # 페이지네이션
    menu_items = query.offset(offset).limit(limit).all()
    
    return menu_items


@router.get("/popular-menus", response_model=List[MenuItemSchema])
async def get_popular_menus(
    market_id: str = None,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    """인기 메뉴 조회 (좋아요 수 기준)"""
    from app.db.models import Like
    from sqlalchemy import func
    
    query = db.query(
        MenuItem,
        func.count(Like.id).label('like_count')
    ).outerjoin(Like).group_by(MenuItem.id)
    
    if market_id:
        query = query.join(MarketMenuItem).filter(MarketMenuItem.market_id == market_id)
    
    # 좋아요 수로 정렬
    popular_items = query.order_by(func.count(Like.id).desc()).limit(limit).all()
    
    return [item[0] for item in popular_items]  # MenuItem 객체만 반환


@router.get("/trending-keywords")
async def get_trending_keywords(
    market_id: str = None,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    """트렌딩 키워드 조회"""
    from app.db.models import KeywordReview
    
    query = db.query(KeywordReview)
    
    if market_id:
        query = query.filter(KeywordReview.market_id == market_id)
    
    trending = query.order_by(KeywordReview.count.desc()).limit(limit).all()
    
    return [
        {
            "keyword": item.keyword,
            "count": item.count,
            "market_id": str(item.market_id)
        }
        for item in trending
    ]
