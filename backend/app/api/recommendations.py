"""
추천 시스템 API 엔드포인트
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import User, MenuItem, Like
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
    """
    사용자 맞춤 추천
    nationality와 birth만 활용
    """
    try:
        recommendation_service = RecommendationService(db)
        
        # 통합 추천 (국적-나이별 트렌드 + 개인 맞춤 + 전체 인기)
        all_recommendations = recommendation_service.get_recommendations(
            user_id=str(current_user.id),
            country=current_user.country,
            birth_yyyy_mm=current_user.birth_yyyy_mm,
            limit=limit
        )
        
        # 개인 맞춤 추천 우선 사용
        recommendations = all_recommendations.get("personalized", [])
        recommendation_type = "personalized"
        
        # 개인 맞춤이 부족하면 국적-나이별 트렌드 추가
        if len(recommendations) < limit:
            trend_recs = all_recommendations.get("nationality_age_trend", [])
            # 중복 제거
            existing_ids = {r.id for r in recommendations}
            for rec in trend_recs:
                if rec.id not in existing_ids and len(recommendations) < limit:
                    recommendations.append(rec)
            if trend_recs:
                recommendation_type = "hybrid"
        
        # 여전히 부족하면 전체 인기 메뉴 추가
        if len(recommendations) < limit:
            popular_recs = all_recommendations.get("popular", [])
            existing_ids = {r.id for r in recommendations}
            for rec in popular_recs:
                if rec.id not in existing_ids and len(recommendations) < limit:
                    recommendations.append(rec)
            if not recommendations:
                recommendation_type = "popular"
        
        return RecommendationResponse(
            success=True,
            recommendations=recommendations[:limit],
            recommendation_type=recommendation_type,
            message=f"{len(recommendations)}개의 추천 메뉴를 찾았습니다"
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"추천 생성 중 오류가 발생했습니다: {str(e)}"
        )


@router.get("/nationality-age-trend", response_model=List[MenuItemSchema])
async def get_nationality_age_trend_recommendations(
    country: Optional[str] = None,
    birth_yyyy_mm: Optional[str] = None,
    limit: int = 3,
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    국적-나이별 트렌드 메뉴 추천
    
    Args:
        country: 국가 코드 (선택, 없으면 현재 사용자 정보 사용)
        birth_yyyy_mm: 생년월 (선택, 없으면 현재 사용자 정보 사용)
        limit: 반환할 메뉴 개수
    """
    try:
        recommendation_service = RecommendationService(db)
        
        # 파라미터가 없으면 현재 사용자 정보 사용
        if not country and current_user:
            country = current_user.country
        if not birth_yyyy_mm and current_user:
            birth_yyyy_mm = current_user.birth_yyyy_mm
        
        recommendations = recommendation_service.get_nationality_age_trend_recommendations(
            country=country,
            birth_yyyy_mm=birth_yyyy_mm,
            limit=limit
        )
        
        return recommendations
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"국적-나이별 트렌드 추천 생성 중 오류가 발생했습니다: {str(e)}"
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
