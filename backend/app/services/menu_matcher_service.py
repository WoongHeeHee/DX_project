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
    
    def match_menu(
        self, 
        image_url: Optional[str] = None, 
        image_base64: Optional[str] = None,
        user_text: Optional[str] = None
    ) -> Optional[str]:
        """
        GPT-4V를 이용하여 메뉴 추출
        
        Args:
            image_url: 이미지 URL (선택, image_base64와 함께 사용 불가)
            image_base64: base64 인코딩된 이미지 (선택, image_url과 함께 사용 불가)
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
            if image_base64:
                # base64 이미지 사용 (메모리에서 직접 처리, 저장하지 않음)
                logger.info(f"메뉴 매칭 시작: base64 이미지 사용, user_text={user_text}")
                
                # base64 데이터 URL 형식으로 변환
                image_data_url = f"data:image/jpeg;base64,{image_base64}"
                
                # 이미지와 텍스트 모두 사용
                response = self.openai_service.client.chat.completions.create(
                    model="gpt-4o",
                    messages=[{
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {"type": "image_url", "image_url": {"url": image_data_url}}
                        ]
                    }],
                    max_tokens=50,
                    temperature=0.1
                )
                
                answer = response.choices[0].message.content.strip()
                logger.info(f"OpenAI 응답: {answer}, 메뉴 목록에 포함 여부: {answer in menus}")
                return answer if answer in menus else None
                
            elif image_url:
                # 이미지 URL 사용
                logger.info(f"메뉴 매칭 시작: image_url={image_url[:100] if image_url else None}..., user_text={user_text}")
                
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
                
                answer = response.choices[0].message.content.strip()
                logger.info(f"OpenAI 응답: {answer}, 메뉴 목록에 포함 여부: {answer in menus}")
                return answer if answer in menus else None
            else:
                # 텍스트만 사용
                logger.info(f"텍스트만으로 메뉴 매칭: user_text={user_text}")
                response = self.openai_service.client.chat.completions.create(
                    model="gpt-4o",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=50,
                    temperature=0.1
                )
                
                answer = response.choices[0].message.content.strip()
                logger.info(f"OpenAI 응답: {answer}, 메뉴 목록에 포함 여부: {answer in menus}")
                return answer if answer in menus else None
            
        except Exception as e:
            logger.error(f"메뉴 매칭 중 오류 발생: {e}", exc_info=True)
            # 더 자세한 오류 정보 로깅
            if hasattr(e, 'response') and e.response:
                logger.error(f"OpenAI API 응답: {e.response}")
            if hasattr(e, 'body') and e.body:
                logger.error(f"OpenAI API 응답 본문: {e.body}")
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

