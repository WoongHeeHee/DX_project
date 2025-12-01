"""
추천 시스템 서비스
nationality와 birth만 활용하여 추천
"""

from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_, extract
import sqlalchemy as sa
from datetime import datetime
import logging

from app.db.models import User, MenuItem, Like, Pin
from app.models.schemas import MenuItem as MenuItemSchema

logger = logging.getLogger(__name__)


class RecommendationService:
    """추천 시스템 서비스 클래스 (nationality와 birth만 활용)"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_nationality_age_trend_recommendations(
        self,
        country: Optional[str] = None,
        birth_yyyy_mm: Optional[str] = None,
        limit: int = 3
    ) -> List[MenuItemSchema]:
        """
        국적-나이별 트렌드 메뉴 추천
        
        Args:
            country: 국가 코드 (ISO 2자리)
            birth_yyyy_mm: 생년월 (YYYY-MM 형식)
            limit: 반환할 메뉴 개수
        
        Returns:
            해당 국적+나이대 사용자들의 좋아요가 많은 메뉴 top N
        """
        try:
            # 나이 계산 (생년월에서)
            birth_year = None
            if birth_yyyy_mm:
                try:
                    birth_year = int(birth_yyyy_mm.split('-')[0])
                except:
                    pass
            
            # 해당 국적+나이대 사용자들 조회
            similar_users_query = self.db.query(User)
            
            if country:
                similar_users_query = similar_users_query.filter(User.country == country)
            
            if birth_year:
                # 나이대 계산 (10년 단위: 20대, 30대 등)
                age_group_start = (birth_year // 10) * 10
                age_group_end = age_group_start + 9
                
                # birth_yyyy_mm 문자열에서 연도 부분만 추출하여 비교
                # YYYY-MM 형식에서 YYYY 부분만 추출
                similar_users_query = similar_users_query.filter(
                    func.cast(func.substring(User.birth_yyyy_mm, 1, 4), sa.Integer).between(
                        age_group_start, age_group_end
                    )
                )
            
            similar_users = similar_users_query.all()
            similar_user_ids = [str(user.id) for user in similar_users]
            
            if not similar_user_ids:
                # 해당 조건의 사용자가 없으면 전체 인기 메뉴 반환
                return self._get_popular_menus(limit)
            
            # 해당 사용자들의 좋아요 집계
            recommended_items = self.db.query(
                MenuItem,
                func.count(Like.id).label('like_count')
            ).join(Like).filter(
                Like.user_id.in_(similar_user_ids)
            ).group_by(
                MenuItem.id
            ).order_by(
                func.count(Like.id).desc()
            ).limit(limit).all()
            
            return [MenuItemSchema.model_validate(item[0]) for item in recommended_items]
            
        except Exception as e:
            logger.error(f"국적-나이별 트렌드 추천 실패: {e}")
            return self._get_popular_menus(limit)
    
    def get_personalized_recommendations(
        self,
        user_id: str,
        limit: int = 3
    ) -> List[MenuItemSchema]:
        """
        개인 맞춤 추천
        찜한 메뉴를 토대로 같은 메뉴를 좋아요를 누른 사람 중 좋아요를 많이 받은 다른 메뉴
        
        Args:
            user_id: 사용자 ID
            limit: 반환할 메뉴 개수
        
        Returns:
            추천 메뉴 리스트
        """
        try:
            # 사용자가 찜한 메뉴 조회
            user_pins = self.db.query(Pin.menu_item_id).filter(
                Pin.user_id == user_id,
                Pin.menu_item_id.isnot(None)
            ).all()
            
            if not user_pins:
                # 찜한 메뉴가 없으면 전체 인기 메뉴 반환
                return self._get_popular_menus(limit)
            
            pinned_menu_ids = [pin.menu_item_id for pin in user_pins]
            
            # 찜한 메뉴들을 좋아요한 다른 사용자들 찾기
            users_who_liked_pinned = self.db.query(
                Like.user_id
            ).filter(
                Like.menu_item_id.in_(pinned_menu_ids),
                Like.user_id != user_id
            ).distinct().all()
            
            similar_user_ids = [user.user_id for user in users_who_liked_pinned]
            
            if not similar_user_ids:
                return self._get_popular_menus(limit)
            
            # 현재 사용자가 이미 좋아요한 메뉴 제외
            user_likes = self.db.query(Like.menu_item_id).filter(
                Like.user_id == user_id
            ).subquery()
            
            # 유사한 사용자들이 좋아요한 다른 메뉴 중 인기순
            recommended_items = self.db.query(
                MenuItem,
                func.count(Like.id).label('like_count')
            ).join(Like).filter(
                Like.user_id.in_(similar_user_ids),
                ~MenuItem.id.in_(user_likes),
                ~MenuItem.id.in_(pinned_menu_ids)  # 찜한 메뉴도 제외
            ).group_by(
                MenuItem.id
            ).order_by(
                func.count(Like.id).desc()
            ).limit(limit).all()
            
            return [MenuItemSchema.model_validate(item[0]) for item in recommended_items]
            
        except Exception as e:
            logger.error(f"개인 맞춤 추천 실패: {e}")
            return self._get_popular_menus(limit)
    
    def _get_popular_menus(self, limit: int = 3) -> List[MenuItemSchema]:
        """전체 인기 메뉴 조회 (fallback)"""
        try:
            popular_items = self.db.query(
                MenuItem,
                func.count(Like.id).label('like_count')
            ).outerjoin(Like).group_by(
                MenuItem.id
            ).order_by(
                func.count(Like.id).desc()
            ).limit(limit).all()
            
            return [MenuItemSchema.model_validate(item[0]) for item in popular_items]
        except Exception as e:
            logger.error(f"인기 메뉴 조회 실패: {e}")
            return []
    
    def get_recommendations(
        self,
        user_id: Optional[str] = None,
        country: Optional[str] = None,
        birth_yyyy_mm: Optional[str] = None,
        limit: int = 10
    ) -> Dict[str, List[MenuItemSchema]]:
        """
        통합 추천 API
        
        Returns:
            {
                "nationality_age_trend": [...],  # 국적-나이별 트렌드
                "personalized": [...],  # 개인 맞춤
                "popular": [...]  # 전체 인기
            }
        """
        result = {
            "nationality_age_trend": [],
            "personalized": [],
            "popular": []
        }
        
        # 국적-나이별 트렌드 추천
        if country or birth_yyyy_mm:
            result["nationality_age_trend"] = self.get_nationality_age_trend_recommendations(
                country=country,
                birth_yyyy_mm=birth_yyyy_mm,
                limit=3
            )
        
        # 개인 맞춤 추천
        if user_id:
            result["personalized"] = self.get_personalized_recommendations(
                user_id=user_id,
                limit=3
            )
        
        # 전체 인기 메뉴
        result["popular"] = self._get_popular_menus(limit=3)
        
        return result
