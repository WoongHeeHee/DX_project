"""
추천 시스템 서비스
"""

import numpy as np
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
import logging

from app.db.models import User, MenuItem, Like, Pin, Event
from app.models.schemas import MenuItem as MenuItemSchema

logger = logging.getLogger(__name__)


class RecommendationService:
    """추천 시스템 서비스 클래스"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_collaborative_recommendations(
        self, 
        user_id: str, 
        limit: int = 10
    ) -> List[MenuItemSchema]:
        """협업 필터링 기반 추천"""
        try:
            # 사용자의 좋아요 기록 조회
            user_likes = self.db.query(Like.menu_item_id).filter(
                Like.user_id == user_id
            ).subquery()
            
            # 유사한 취향을 가진 사용자 찾기
            similar_users = self.db.query(
                Like.user_id,
                func.count(Like.menu_item_id).label('common_likes')
            ).filter(
                Like.menu_item_id.in_(user_likes),
                Like.user_id != user_id
            ).group_by(Like.user_id).order_by(
                func.count(Like.menu_item_id).desc()
            ).limit(20).all()
            
            if not similar_users:
                return []
            
            # 유사한 사용자들이 좋아하는 메뉴 중 현재 사용자가 좋아하지 않은 것들
            similar_user_ids = [user.user_id for user in similar_users]
            
            recommended_items = self.db.query(
                MenuItem,
                func.count(Like.id).label('recommendation_score')
            ).join(Like).filter(
                Like.user_id.in_(similar_user_ids),
                ~MenuItem.id.in_(user_likes)
            ).group_by(MenuItem.id).order_by(
                func.count(Like.id).desc()
            ).limit(limit).all()
            
            return [MenuItemSchema.model_validate(item[0]) for item in recommended_items]
            
        except Exception as e:
            logger.error(f"협업 필터링 추천 실패: {e}")
            return []
    
    def get_popularity_recommendations(
        self,
        user_preferences: Dict[str, Any],
        limit: int = 10,
        exclude_ids: List[str] = None
    ) -> List[MenuItemSchema]:
        """인기도 기반 추천 (사용자 선호도 고려)"""
        try:
            query = self.db.query(
                MenuItem,
                func.count(Like.id).label('like_count')
            ).outerjoin(Like).group_by(MenuItem.id)
            
            # 제외할 아이템들
            if exclude_ids:
                query = query.filter(~MenuItem.id.in_(exclude_ids))
            
            # 매운맛 수준 필터링
            spice_level = user_preferences.get('spice_level')
            if spice_level:
                query = query.filter(MenuItem.spice_level <= spice_level)
            
            # 모험 수준에 따른 필터링
            adventure = user_preferences.get('adventure')
            if adventure == 'conservative':
                query = query.filter(MenuItem.spice_level <= 2)
            elif adventure == 'moderate':
                query = query.filter(MenuItem.spice_level <= 4)
            
            # 인기도순 정렬 (좋아요 수 + 스무딩)
            popular_items = query.order_by(
                func.count(Like.id).desc()
            ).limit(limit).all()
            
            return [MenuItemSchema.model_validate(item[0]) for item in popular_items]
            
        except Exception as e:
            logger.error(f"인기도 추천 실패: {e}")
            return []
    
    def get_similar_users_recommendations(
        self,
        user_id: str,
        limit: int = 10
    ) -> List[MenuItemSchema]:
        """유사한 사용자 기반 추천"""
        try:
            # 현재 사용자 정보
            current_user = self.db.query(User).filter(User.id == user_id).first()
            if not current_user:
                return []
            
            # 유사한 프로필을 가진 사용자들 찾기
            similar_users_query = self.db.query(User).filter(
                User.id != user_id
            )
            
            # 국가가 같은 사용자 우선
            if current_user.country:
                similar_users_query = similar_users_query.filter(
                    or_(
                        User.country == current_user.country,
                        User.country.is_(None)
                    )
                )
            
            # 비슷한 매운맛 수준 (±1)
            if current_user.spice_level:
                similar_users_query = similar_users_query.filter(
                    and_(
                        User.spice_level >= current_user.spice_level - 1,
                        User.spice_level <= current_user.spice_level + 1
                    )
                )
            
            # 같은 모험 수준
            if current_user.adventure:
                similar_users_query = similar_users_query.filter(
                    User.adventure == current_user.adventure
                )
            
            similar_users = similar_users_query.limit(50).all()
            similar_user_ids = [user.id for user in similar_users]
            
            if not similar_user_ids:
                return []
            
            # 현재 사용자가 좋아하지 않은 메뉴 중 유사한 사용자들이 좋아하는 것들
            user_likes = self.db.query(Like.menu_item_id).filter(
                Like.user_id == user_id
            ).subquery()
            
            recommended_items = self.db.query(
                MenuItem,
                func.count(Like.id).label('similar_user_likes')
            ).join(Like).filter(
                Like.user_id.in_(similar_user_ids),
                ~MenuItem.id.in_(user_likes)
            ).group_by(MenuItem.id).order_by(
                func.count(Like.id).desc()
            ).limit(limit).all()
            
            return [MenuItemSchema.model_validate(item[0]) for item in recommended_items]
            
        except Exception as e:
            logger.error(f"유사 사용자 추천 실패: {e}")
            return []
    
    def get_content_based_recommendations(
        self,
        user_id: str,
        limit: int = 10
    ) -> List[MenuItemSchema]:
        """콘텐츠 기반 추천 (사용자가 좋아한 메뉴와 유사한 특성)"""
        try:
            # 사용자가 좋아한 메뉴들의 특성 분석
            liked_menus = self.db.query(MenuItem).join(Like).filter(
                Like.user_id == user_id
            ).all()
            
            if not liked_menus:
                return []
            
            # 평균 매운맛 수준 계산
            avg_spice_level = np.mean([menu.spice_level for menu in liked_menus])
            
            # 좋아한 메뉴의 태그 분석
            all_tags = []
            for menu in liked_menus:
                if menu.tags:
                    all_tags.extend(menu.tags.get('categories', []))
            
            # 가장 빈번한 태그들
            from collections import Counter
            common_tags = [tag for tag, count in Counter(all_tags).most_common(5)]
            
            # 유사한 특성을 가진 메뉴 추천
            user_likes = self.db.query(Like.menu_item_id).filter(
                Like.user_id == user_id
            ).subquery()
            
            query = self.db.query(MenuItem).filter(
                ~MenuItem.id.in_(user_likes)
            )
            
            # 매운맛 수준이 비슷한 메뉴 (±1)
            query = query.filter(
                and_(
                    MenuItem.spice_level >= max(1, int(avg_spice_level) - 1),
                    MenuItem.spice_level <= min(5, int(avg_spice_level) + 1)
                )
            )
            
            # 태그 기반 필터링 (PostgreSQL JSONB 연산 사용)
            if common_tags:
                for tag in common_tags[:3]:  # 상위 3개 태그만 사용
                    query = query.filter(
                        MenuItem.tags.op('?')(tag)
                    )
            
            similar_menus = query.limit(limit).all()
            
            return [MenuItemSchema.model_validate(menu) for menu in similar_menus]
            
        except Exception as e:
            logger.error(f"콘텐츠 기반 추천 실패: {e}")
            return []
    
    def calculate_user_similarity(self, user1_id: str, user2_id: str) -> float:
        """두 사용자 간의 유사도 계산"""
        try:
            # 공통으로 좋아요한 메뉴 수
            user1_likes = set(
                like.menu_item_id for like in 
                self.db.query(Like).filter(Like.user_id == user1_id).all()
            )
            user2_likes = set(
                like.menu_item_id for like in 
                self.db.query(Like).filter(Like.user_id == user2_id).all()
            )
            
            if not user1_likes or not user2_likes:
                return 0.0
            
            # Jaccard 유사도 계산
            intersection = len(user1_likes.intersection(user2_likes))
            union = len(user1_likes.union(user2_likes))
            
            return intersection / union if union > 0 else 0.0
            
        except Exception as e:
            logger.error(f"사용자 유사도 계산 실패: {e}")
            return 0.0
    
    def get_cold_start_recommendations(
        self,
        user_preferences: Dict[str, Any],
        limit: int = 10
    ) -> List[MenuItemSchema]:
        """신규 사용자를 위한 콜드 스타트 추천"""
        try:
            # 전체적으로 인기 있는 메뉴 중 사용자 선호도에 맞는 것들
            query = self.db.query(
                MenuItem,
                func.count(Like.id).label('popularity_score')
            ).outerjoin(Like).group_by(MenuItem.id)
            
            # 매운맛 수준 필터링
            spice_level = user_preferences.get('spice_level', 3)
            query = query.filter(MenuItem.spice_level <= spice_level)
            
            # 한국 경험에 따른 필터링
            korean_experience = user_preferences.get('korean_experience')
            if korean_experience == 'first_time':
                # 첫 방문자는 매운맛 1-2 수준만
                query = query.filter(MenuItem.spice_level <= 2)
            elif korean_experience == 'some_experience':
                # 어느 정도 경험자는 매운맛 3 수준까지
                query = query.filter(MenuItem.spice_level <= 3)
            
            # 인기도순 정렬
            popular_items = query.order_by(
                func.count(Like.id).desc()
            ).limit(limit).all()
            
            return [MenuItemSchema.model_validate(item[0]) for item in popular_items]
            
        except Exception as e:
            logger.error(f"콜드 스타트 추천 실패: {e}")
            return []
