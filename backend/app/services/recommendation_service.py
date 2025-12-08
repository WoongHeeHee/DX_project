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
from datetime import date, datetime
from urllib.parse import quote

from app.db.models import User, MenuItem, Like
from app.models.schemas import MenuItem as MenuItemSchema

logger = logging.getLogger(__name__)


class RecommendationService:
    """추천 시스템 서비스 클래스 (nationality와 birth만 활용)"""
    
    def __init__(self, db: Session):
        self.db = db

        # 국적 21개 x 연령층 9개 조합에 대해 균형 있게 분산될 수 있도록
        # 미리 준비한 메뉴 풀(실제 menu_items.id)에서 라운드로빈 방식으로 3개를 선택한다.
        self._fallback_menu_pool: List[str] = [
            # (id 목록만 저장, 실제 조회 시 DB에서 로드)
            "ME155",  # 떡볶이
            "ME012",  # 김밥
            "ME148",  # 닭강정
            "ME016",  # 꼬마김밥
            "ME243",  # 꽈배기
            "ME347",  # 꼬막비빔국수
            "ME346",  # 콧등치기국수
            "ME343",  # 소머리국밥
            "ME351",  # 장터국밥
            "ME349",  # 헛제사밥
            "ME352",  # 술빵
            "ME275",  # 오메기떡
            "ME237",  # 공갈빵
            "ME146",  # 납작만두
            "ME191",  # 옛날통닭
            "ME197",  # 육회
            "ME192",  # 오징어순대
            "ME243",  # 꽈배기(중복 방지용으로 충분한 풀 확보)
            "ME348",  # 간고등어
            "ME353",  # 찜닭
            "ME134",  # 기름떡볶이
            "ME131",  # 구운옥수수
            "ME350",  # 육전
            "ME345",  # 곤드레밥
        ]

        self._country_order: List[str] = [
            "JP",
            "US",
            "CN",
            "KR",
            "TH",
            "VN",
            "SG",
            "MY",
            "ID",
            "PH",
            "IN",
            "TW",
            "HK",
            "AU",
            "CA",
            "GB",
            "FR",
            "DE",
            "RU",
            "MX",
            "MN",
        ]

        # 9개 연령대 인덱스용 구간 정의 (<10, 10대, 20대, ..., 80+)
        self._age_bands = [10, 20, 30, 40, 50, 60, 70, 80, 10**9]
    
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
                # 해당 조건의 사용자가 없으면 국적/연령별 사전 고정 fallback 사용
                return self._get_fallback_by_country_age(country, birth_yyyy_mm, limit)
            
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
            return self._get_fallback_by_country_age(country, birth_yyyy_mm, limit)
    
    def get_personalized_recommendations(
        self,
        user_id: str,
        limit: int = 3
    ) -> List[MenuItemSchema]:
        """
        개인 맞춤 추천
        사용자가 좋아요한 메뉴를 토대로 같은 메뉴를 좋아요를 누른 사람 중 좋아요를 많이 받은 다른 메뉴
        
        Args:
            user_id: 사용자 ID
            limit: 반환할 메뉴 개수
        
        Returns:
            추천 메뉴 리스트
        """
        try:
            # 사용자가 좋아요한 메뉴 조회
            user_likes = self.db.query(Like.menu_item_id).filter(
                Like.user_id == user_id
            ).all()
            
            if not user_likes:
                # 좋아요한 메뉴가 없으면 전체 인기 메뉴 반환
                return self._get_popular_menus(limit)
            
            liked_menu_ids = [like.menu_item_id for like in user_likes]
            
            # 좋아요한 메뉴들을 좋아요한 다른 사용자들 찾기
            users_who_liked_same = self.db.query(
                Like.user_id
            ).filter(
                Like.menu_item_id.in_(liked_menu_ids),
                Like.user_id != user_id
            ).distinct().all()
            
            similar_user_ids = [user.user_id for user in users_who_liked_same]
            
            if not similar_user_ids:
                return self._get_popular_menus(limit)
            
            # 현재 사용자가 이미 좋아요한 메뉴 제외
            user_likes_subquery = self.db.query(Like.menu_item_id).filter(
                Like.user_id == user_id
            ).subquery()
            
            # 유사한 사용자들이 좋아요한 다른 메뉴 중 인기순
            recommended_items = self.db.query(
                MenuItem,
                func.count(Like.id).label('like_count')
            ).join(Like).filter(
                Like.user_id.in_(similar_user_ids),
                ~MenuItem.id.in_(user_likes_subquery)
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

    # --- Fallback helpers ---
    def _age_band_index(self, birth_yyyy_mm: Optional[str]) -> int:
        """birth_yyyy_mm을 기반으로 9개 연령대 인덱스 반환"""
        try:
            if not birth_yyyy_mm:
                return 2  # 기본: 20대
            year = int(birth_yyyy_mm.split("-")[0])
            current_year = date.today().year
            age = current_year - year
            for idx, upper in enumerate(self._age_bands):
                if age < upper:
                    return idx
            return len(self._age_bands) - 1
        except Exception:
            return 2  # 파싱 실패 시 20대

    def _country_index(self, country: Optional[str]) -> int:
        """국가 코드를 사전 정의 순서 인덱스로 매핑"""
        if not country:
            return 0
        code = country.upper()
        try:
            return self._country_order.index(code)
        except ValueError:
            return 0

    def _get_fallback_by_country_age(
        self,
        country: Optional[str],
        birth_yyyy_mm: Optional[str],
        limit: int = 3,
    ) -> List[MenuItemSchema]:
        """
        국적/연령별 고정 fallback (likes 데이터가 비었을 때 사용)
        21개 국가 x 9개 연령을 고르게 분산시키기 위해
        라운드로빈 방식으로 3개씩 선택.
        """
        pool = self._fallback_menu_pool
        if not pool:
            return []

        c_idx = self._country_index(country)
        a_idx = self._age_band_index(birth_yyyy_mm)
        seed = (c_idx * len(self._age_bands) + a_idx) % len(pool)

        # 고르게 분산: 간격을 두고 3개 뽑기
        picks = [
            pool[seed % len(pool)],
            pool[(seed + 7) % len(pool)],
            pool[(seed + 13) % len(pool)],
        ][:limit]

        # DB에서 실제 메뉴 조회 (순서 유지)
        menu_rows = (
            self.db.query(MenuItem)
            .filter(MenuItem.id.in_(picks))
            .all()
        )
        row_map = {m.id: m for m in menu_rows}
        result: List[MenuItemSchema] = []
        for pid in picks:
            if pid in row_map:
                result.append(self._to_schema_with_defaults(row_map[pid]))

        if not result:
            # 풀에 없는 ID가 모두 실패한 경우, 정적 스키마 + 플레이스홀더 이미지로 반환
            static_items: List[MenuItemSchema] = []
            for pid in picks:
                name = self._fallback_name(pid)
                encoded = quote(name)
                image_url = (
                    f"https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/"
                    f"{encoded}/{encoded}1_{pid}.png"
                )
                static_items.append(
                    MenuItemSchema(
                        id=pid,
                        name=name,
                        rep_image_url=image_url,
                        category="Meals",
                        spice_level=1,
                        created_at=datetime.utcnow(),
                    )
                )
            return static_items[:limit]
        return result[:limit]

    def _fallback_name(self, menu_id: str) -> str:
        """메뉴 ID에 대한 기본 이름 매핑 (없으면 ID 반환)"""
        mapping = {
            "ME155": "떡볶이",
            "ME012": "김밥",
            "ME148": "닭강정",
            "ME016": "꼬마김밥",
            "ME243": "꽈배기",
            "ME347": "꼬막비빔국수",
            "ME346": "콧등치기국수",
            "ME343": "소머리국밥",
            "ME351": "장터국밥",
            "ME349": "헛제사밥",
            "ME352": "술빵",
            "ME275": "오메기떡",
            "ME237": "공갈빵",
            "ME146": "납작만두",
            "ME191": "옛날통닭",
            "ME197": "육회",
            "ME192": "오징어순대",
            "ME348": "간고등어",
            "ME353": "찜닭",
            "ME134": "기름떡볶이",
            "ME131": "구운옥수수",
            "ME350": "육전",
            "ME345": "곤드레밥",
        }
        return mapping.get(menu_id, menu_id)

    def _to_schema_with_defaults(self, m: MenuItem) -> MenuItemSchema:
        """MenuItem ORM 객체를 스키마로 변환할 때 created_at/rep_image_url이 없으면 안전한 기본값을 채운다."""
        created_at = m.created_at or datetime.utcnow()
        name = m.name or self._fallback_name(m.id)
        rep_image_url = m.rep_image_url or (
            f"https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/"
            f"{quote(name)}/{quote(name)}1_{m.id}.png"
        )

        return MenuItemSchema(
            id=m.id,
            name=name,
            name_en=getattr(m, "name_en", None),
            name_zh=getattr(m, "name_zh", None),
            name_ja=getattr(m, "name_ja", None),
            description=getattr(m, "description", None),
            description_en=getattr(m, "description_en", None),
            description_zh=getattr(m, "description_zh", None),
            description_ja=getattr(m, "description_ja", None),
            similar_food=getattr(m, "similar_food", None),
            similar_food_en=getattr(m, "similar_food_en", None),
            similar_food_zh=getattr(m, "similar_food_zh", None),
            similar_food_ja=getattr(m, "similar_food_ja", None),
            rep_image_url=rep_image_url,
            price=getattr(m, "price", None),
            contains=getattr(m, "contains", None),
            contains_en=getattr(m, "contains_en", None),
            contains_zh=getattr(m, "contains_zh", None),
            contains_ja=getattr(m, "contains_ja", None),
            may_contains=getattr(m, "may_contains", None),
            may_contains_en=getattr(m, "may_contains_en", None),
            may_contains_zh=getattr(m, "may_contains_zh", None),
            may_contains_ja=getattr(m, "may_contains_ja", None),
            category=getattr(m, "category", None),
            spice_level=(m.spice_level or 1) if hasattr(m, "spice_level") else 1,
            created_at=created_at,
        )
    
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
