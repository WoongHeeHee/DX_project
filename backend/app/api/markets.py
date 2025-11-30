"""
시장 관련 API 엔드포인트
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import Market, MenuItem, Shop
from app.models.schemas import Market as MarketSchema, MenuItem as MenuItemSchema, MarketStats

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
    
    menu_items = db.query(MenuItem).filter(MenuItem.market_id == market_id).all()
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
    
    # 메뉴 아이템 수
    total_menu_items = db.query(MenuItem).filter(MenuItem.market_id == market_id).count()
    
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
