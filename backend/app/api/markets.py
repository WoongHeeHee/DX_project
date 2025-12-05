"""
시장 관련 API 엔드포인트
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import Market, MenuItem, Shop, MarketMenuItem, MarketInfo
from app.models.schemas import Market as MarketSchema, MenuItem as MenuItemSchema, MarketStats, MarketInfo as MarketInfoSchema, MarketInfoCreate

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
    
    return market_info


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
