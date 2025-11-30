"""
검색 관련 API 엔드포인트
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import MenuItem, Shop, ShopMenu
from app.models.schemas import (
    ImageSearchRequest, 
    ImageSearchResponse, 
    SearchResult,
    MenuItem as MenuItemSchema,
    ShopWithDistance
)
from app.services.openai_service import OpenAIService
from app.services.pinecone_service import PineconeService
from app.api.shops import get_nearby_shops
from app.models.schemas import NearbyShopsRequest

router = APIRouter()


@router.post("/image", response_model=ImageSearchResponse)
async def search_by_image(
    request: ImageSearchRequest,
    db: Session = Depends(get_db)
):
    """이미지로 음식 검색"""
    try:
        openai_service = OpenAIService()
        pinecone_service = PineconeService()
        
        # 1. 이미지 분석
        analysis_result = openai_service.analyze_food_image(request.image_url)
        
        if not analysis_result.get('is_food'):
            return ImageSearchResponse(
                success=True,
                results=[],
                message="음식 이미지가 감지되지 않았습니다"
            )
        
        # 2. 이미지 임베딩 생성
        image_embedding = openai_service.generate_image_embedding(request.image_url)
        
        if not image_embedding:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="이미지 임베딩 생성에 실패했습니다"
            )
        
        # 3. Pinecone에서 유사한 메뉴 검색
        similar_menus = pinecone_service.search_similar_menus(
            query_embedding=image_embedding,
            top_k=10
        )
        
        # 4. 검색 결과 구성
        results = []
        for menu_match in similar_menus:
            menu_item_id = menu_match.get('menu_item_id')
            confidence = menu_match.get('score', 0.0)
            
            # 메뉴 아이템 정보 조회
            menu_item = db.query(MenuItem).filter(MenuItem.id == menu_item_id).first()
            if not menu_item:
                continue
            
            # 근처 가게 검색 (위치 정보가 있는 경우)
            shops_nearby = []
            if request.lat is not None and request.lng is not None:
                nearby_request = NearbyShopsRequest(
                    lat=request.lat,
                    lng=request.lng,
                    radius_meters=1000,  # 1km 반경
                    market_id=menu_item.market_id
                )
                
                # 해당 메뉴를 판매하는 가게만 필터링
                shops_with_menu = db.query(Shop).join(ShopMenu).filter(
                    ShopMenu.menu_item_id == menu_item.id,
                    ShopMenu.available == True
                ).all()
                
                # 거리 계산은 별도 함수로 처리 (간단화)
                for shop in shops_with_menu[:5]:  # 최대 5개
                    shops_nearby.append(ShopWithDistance(
                        id=shop.id,
                        market_id=shop.market_id,
                        name=shop.name,
                        name_en=shop.name_en,
                        name_zh=shop.name_zh,
                        name_ja=shop.name_ja,
                        lat=shop.lat,
                        lng=shop.lng,
                        address=shop.address,
                        last_reported_open_at=shop.last_reported_open_at,
                        created_at=shop.created_at,
                        distance_meters=0.0  # 실제로는 계산 필요
                    ))
            
            results.append(SearchResult(
                menu_item=MenuItemSchema.model_validate(menu_item),
                confidence=confidence,
                shops_nearby=shops_nearby
            ))
        
        return ImageSearchResponse(
            success=True,
            results=results,
            message=f"{len(results)}개의 검색 결과를 찾았습니다"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"이미지 검색 중 오류가 발생했습니다: {str(e)}"
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
    
    # 시장 필터
    if market_id:
        query = query.filter(MenuItem.market_id == market_id)
    
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
        query = query.filter(MenuItem.market_id == market_id)
    
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
