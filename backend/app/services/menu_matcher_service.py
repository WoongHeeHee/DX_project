"""
메뉴 매칭 서비스
기존 src/menu_matcher.py를 backend 구조에 맞게 통합
"""

import logging
from typing import Optional, List
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import MenuItem
from app.services.openai_service import OpenAIService

logger = logging.getLogger(__name__)


class MenuMatcherService:
    """메뉴 매칭 서비스"""
    
    def __init__(self, db: Session):
        self.db = db
        self.openai_service = OpenAIService()
    
    def get_all_menus(self) -> List[str]:
        """DB에서 모든 메뉴 리스트 반환"""
        menu_items = self.db.query(MenuItem).all()
        return [item.name for item in menu_items]
    
    def match_menu(self, image_url: Optional[str] = None, user_text: Optional[str] = None) -> Optional[str]:
        """
        GPT-4V를 이용하여 메뉴 추출
        
        Args:
            image_url: 이미지 URL (선택)
            user_text: 사용자가 입력한 음식 묘사 (선택)
        
        Returns:
            메뉴 이름 혹은 None
        """
        menus = self.get_all_menus()
        if not menus:
            logger.warning("메뉴 목록이 비어있습니다")
            return None
        
        menu_list_str = ", ".join(menus)
        prompt = f"다음 메뉴 중 하나만 선택하세요: [{menu_list_str}]\n"
        if user_text:
            prompt += f"사용자 설명: \"{user_text}\"\n"
        prompt += "메뉴 이름 혹은 None 만 출력하세요."
        
        try:
            if image_url:
                # 이미지와 텍스트 모두 사용
                response = self.openai_service.client.chat.completions.create(
                    model="gpt-4o",
                    messages=[{
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {"type": "image_url", "image_url": {"url": image_url}}
                        ]
                    }],
                    max_tokens=50,
                    temperature=0.1
                )
            else:
                # 텍스트만 사용
                response = self.openai_service.client.chat.completions.create(
                    model="gpt-4o",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=50,
                    temperature=0.1
                )
            
            answer = response.choices[0].message.content.strip()
            return answer if answer in menus else None
            
        except Exception as e:
            logger.error(f"메뉴 매칭 중 오류 발생: {e}")
            return None


def get_all_menus(db: Session) -> List[str]:
    """편의 함수: 모든 메뉴 리스트 반환"""
    service = MenuMatcherService(db)
    return service.get_all_menus()


def match_menu(image_url: Optional[str] = None, user_text: Optional[str] = None, db: Optional[Session] = None) -> Optional[str]:
    """
    편의 함수: 메뉴 매칭
    
    Args:
        image_url: 이미지 URL (선택)
        user_text: 사용자 텍스트 (선택)
        db: 데이터베이스 세션 (선택, 없으면 새로 생성)
    
    Returns:
        메뉴 이름 혹은 None
    """
    if db is None:
        from app.db.database import SessionLocal
        db = SessionLocal()
        try:
            service = MenuMatcherService(db)
            return service.match_menu(image_url, user_text)
        finally:
            db.close()
    else:
        service = MenuMatcherService(db)
        return service.match_menu(image_url, user_text)

