"""
한국 이름 생성 서비스
"""

from typing import Tuple, Optional
from openai import OpenAI
import logging

from app.config import settings

logger = logging.getLogger(__name__)


class KoreanNameService:
    """한국 이름 생성 서비스"""
    
    def __init__(self):
        self.client = OpenAI(api_key=settings.OPENAI_API_KEY)
    
    def generate_korean_name(self, input_name: str) -> Tuple[str, str]:
        """
        외국 이름을 한국식으로 자연스럽게 변형하여 발음과 유사한 한국 이름과 영어 발음을 반환.
        
        Args:
            input_name (str): 사용자 입력 이름 (영어, 중국어, 일본어 등 가능)
        
        Returns:
            Tuple[str, str]: (한국이름, 영어발음) 튜플
        """
        system_prompt = """
당신의 역할은 '외국 이름을 한국식으로 자연스럽게 변형하여 발음과 유사한 한국 이름 하나를 추천'하는 것입니다.

규칙:
1. 입력 이름의 발음을 그대로 옮기지 말고, 한국식 음운에 맞게 자연스럽게 수정. 
   (예: Donald Trump -> 도널드(x), 두말돈)
2. 출력은 무조건 한 개의 한국 이름과 영어 발음만 (예: (홍록기, Hong-Loggi))
3. 설명, 부연설명, 따옴표, 접두사 없이 (이름, 영어발음)만 출력
4. 한국식 실존 느낌이 나는 2~4음절 이름을 추천.
5. 영어, 중국어, 일본어 등 어떤 언어 이름이 들어와도 발음을 기반으로 자연스러운 한국식 이름 하나를 생성.
"""
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": input_name}
                ],
                max_tokens=50,
                temperature=0.7
            )
            
            result = response.choices[0].message.content.strip()
            
            # "(이름, 발음)" 형식을 파싱
            # 예: "(홍록기, Hong-Loggi)" 또는 "홍록기, Hong-Loggi"
            result = result.strip()
            
            # 괄호 제거
            if result.startswith("(") and result.endswith(")"):
                result = result[1:-1].strip()
            
            # 쉼표로 분리
            parts = [part.strip() for part in result.split(",")]
            
            if len(parts) >= 2:
                korean_name = parts[0].strip()
                english_pronunciation = parts[1].strip()
            elif len(parts) == 1:
                # 발음이 없는 경우
                korean_name = parts[0].strip()
                english_pronunciation = ""
            else:
                raise ValueError("이름 생성 결과 형식이 올바르지 않습니다")
            
            return korean_name, english_pronunciation
            
        except Exception as e:
            logger.error(f"한국 이름 생성 중 오류 발생: {e}")
            raise


def generate_similar_korean_name(input_name: str) -> Tuple[str, str]:
    """
    편의 함수: 한국 이름 생성
    
    Args:
        input_name (str): 사용자 입력 이름
    
    Returns:
        Tuple[str, str]: (한국이름, 영어발음) 튜플
    """
    service = KoreanNameService()
    return service.generate_korean_name(input_name)

