"""
추천 시스템 API 엔드포인트
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import User, MenuItem, Like, Pin
from app.models.schemas import (
    RecommendationRequest,
    RecommendationResponse,
    MenuItem as MenuItemSchema
)
from app.api.auth import get_current_user
from app.services.recommendation_service import RecommendationService

router = APIRouter()


@router.get("/", response_model=RecommendationResponse)
async def get_recommendations(
    limit: int = 10,
    category: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """사용자 맞춤 추천"""
    try:
        recommendation_service = RecommendationService(db)
        
        # 사용자의 활동 기록 확인
        user_likes_count = db.query(Like).filter(Like.user_id == current_user.id).count()
        user_pins_count = db.query(Pin).filter(Pin.user_id == current_user.id).count()
        
        recommendations = []
        recommendation_type = "cold_start"
        
        if user_likes_count >= 3 or user_pins_count >= 2:
            # 충분한 활동이 있는 경우 - 협업 필터링
            recommendations = recommendation_service.get_collaborative_recommendations(
                user_id=current_user.id,
                limit=limit
            )
            recommendation_type = "collaborative"
        
        # 협업 필터링 결과가 부족한 경우 인기도 기반으로 보완
        if len(recommendations) < limit:
            popularity_recommendations = recommendation_service.get_popularity_recommendations(
                user_preferences={
                    "country": current_user.country,
                    "spice_level": current_user.spice_level,
                    "adventure": current_user.adventure,
                    "korean_experience": current_user.korean_experience
                },
                limit=limit - len(recommendations),
                exclude_ids=[r.id for r in recommendations]
            )
            recommendations.extend(popularity_recommendations)
            
            if recommendation_type == "collaborative" and popularity_recommendations:
                recommendation_type = "hybrid"
            elif not recommendations:
                recommendation_type = "popularity"
        
        return RecommendationResponse(
            success=True,
            recommendations=recommendations,
            recommendation_type=recommendation_type,
            message=f"{len(recommendations)}개의 추천 메뉴를 찾았습니다"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"추천 생성 중 오류가 발생했습니다: {str(e)}"
        )


@router.get("/similar-users", response_model=List[MenuItemSchema])
async def get_similar_users_recommendations(
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """유사한 사용자 기반 추천"""
    try:
        recommendation_service = RecommendationService(db)
        
        recommendations = recommendation_service.get_similar_users_recommendations(
            user_id=current_user.id,
            limit=limit
        )
        
        return recommendations
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"유사 사용자 추천 생성 중 오류가 발생했습니다: {str(e)}"
        )


@router.get("/trending", response_model=List[MenuItemSchema])
async def get_trending_recommendations(
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """트렌딩 메뉴 추천"""
    try:
        from datetime import datetime, timedelta
        from sqlalchemy import func
        
        # 최근 7일간의 좋아요 기준
        week_ago = datetime.utcnow() - timedelta(days=7)
        
        trending_query = db.query(
            MenuItem,
            func.count(Like.id).label('recent_likes')
        ).outerjoin(Like).filter(
            Like.created_at >= week_ago
        ).group_by(MenuItem.id).order_by(
            func.count(Like.id).desc()
        ).limit(limit)
        
        # 사용자 선호도 고려 (매운맛 수준)
        if current_user.spice_level:
            trending_query = trending_query.filter(
                MenuItem.spice_level <= current_user.spice_level
            )
        
        trending_items = trending_query.all()
        
        return [item[0] for item in trending_items]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"트렌딩 추천 생성 중 오류가 발생했습니다: {str(e)}"
        )


@router.get("/for-beginners", response_model=List[MenuItemSchema])
async def get_beginner_recommendations(
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """한국 음식 초보자를 위한 추천"""
    try:
        # 초보자 친화적인 메뉴 (낮은 매운맛, 인기 메뉴)
        beginner_friendly = db.query(MenuItem).filter(
            MenuItem.spice_level <= 2  # 매운맛 수준 2 이하
        )
        
        # 사용자의 모험 수준 고려
        if current_user.adventure == "conservative":
            beginner_friendly = beginner_friendly.filter(MenuItem.spice_level <= 1)
        
        # 인기도순 정렬 (좋아요 수 기준)
        from sqlalchemy import func
        popular_beginners = beginner_friendly.outerjoin(Like).group_by(
            MenuItem.id
        ).order_by(
            func.count(Like.id).desc()
        ).limit(limit).all()
        
        return popular_beginners
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"초보자 추천 생성 중 오류가 발생했습니다: {str(e)}"
        )


@router.post("/feedback")
async def submit_recommendation_feedback(
    menu_item_id: str,
    feedback: str,  # "like", "dislike", "not_interested"
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """추천 피드백 제출"""
    try:
        # 피드백을 이벤트로 기록
        from app.db.models import Event, ActionType, TargetType
        
        action_map = {
            "like": ActionType.LIKE,
            "dislike": ActionType.LIKE,  # 부정적 피드백도 일종의 상호작용
            "not_interested": ActionType.LIKE
        }
        
        if feedback in action_map:
            event = Event(
                user_id=current_user.id,
                action_type=action_map[feedback],
                target_type=TargetType.MENU_ITEM,
                target_id=menu_item_id
            )
            db.add(event)
            
            # 좋아요인 경우 Like 테이블에도 추가
            if feedback == "like":
                existing_like = db.query(Like).filter(
                    Like.user_id == current_user.id,
                    Like.menu_item_id == menu_item_id
                ).first()
                
                if not existing_like:
                    like = Like(
                        user_id=current_user.id,
                        menu_item_id=menu_item_id
                    )
                    db.add(like)
            
            db.commit()
        
        return {"success": True, "message": "피드백이 기록되었습니다"}
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"피드백 제출 중 오류가 발생했습니다: {str(e)}"
        )
