"""
OpenAI 서비스 래퍼
"""

import openai
from typing import List, Dict, Any, Optional
import logging
import base64
import requests
from io import BytesIO

from app.config import settings

logger = logging.getLogger(__name__)

# OpenAI 클라이언트 설정
openai.api_key = settings.OPENAI_API_KEY


class OpenAIService:
    """OpenAI 서비스 클래스"""
    
    def __init__(self):
        self.client = openai.OpenAI(api_key=settings.OPENAI_API_KEY)
    
    def analyze_food_image(self, image_url: str) -> Dict[str, Any]:
        """음식 이미지 분석"""
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": """이미지를 분석하여 다음 정보를 JSON 형태로 반환해주세요:
                                {
                                    "is_food": true/false,
                                    "food_coverage": 0.0-1.0,
                                    "food_count": 숫자,
                                    "detected_foods": [
                                        {
                                            "name": "음식명",
                                            "confidence": 0.0-1.0,
                                            "bbox": [x1, y1, x2, y2],
                                            "korean_name": "한국어 음식명"
                                        }
                                    ],
                                    "is_suitable_for_display": true/false
                                }"""
                            },
                            {
                                "type": "image_url",
                                "image_url": {"url": image_url}
                            }
                        ]
                    }
                ],
                max_tokens=500,
                temperature=0.1
            )
            
            import json
            result = json.loads(response.choices[0].message.content.strip())
            return result
            
        except Exception as e:
            logger.error(f"OpenAI 이미지 분석 실패: {e}")
            return {
                "is_food": False,
                "food_coverage": 0.0,
                "food_count": 0,
                "detected_foods": [],
                "is_suitable_for_display": False
            }
    
    def match_menu_item(self, image_url: str, menu_items: List[str], user_prompt: Optional[str] = None) -> Dict[str, Any]:
        """메뉴 아이템 매칭"""
        menu_list = ", ".join(menu_items)
        
        prompt = f"""이미지의 음식을 다음 메뉴 중에서 찾아주세요: [{menu_list}]
        
        JSON 형태로 응답해주세요:
        {{
            "matched_menu": "메뉴명 또는 null",
            "confidence": 0.0-1.0,
            "alternatives": ["대안1", "대안2"]
        }}"""
        
        if user_prompt:
            prompt += f"\n\n사용자 설명: {user_prompt}"
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {"type": "image_url", "image_url": {"url": image_url}}
                        ]
                    }
                ],
                max_tokens=200,
                temperature=0.1
            )
            
            import json
            result = json.loads(response.choices[0].message.content.strip())
            return result
            
        except Exception as e:
            logger.error(f"메뉴 매칭 실패: {e}")
            return {
                "matched_menu": None,
                "confidence": 0.0,
                "alternatives": []
            }
    
    def generate_embedding(self, text: str) -> List[float]:
        """텍스트 임베딩 생성"""
        try:
            response = self.client.embeddings.create(
                model="text-embedding-ada-002",
                input=text
            )
            return response.data[0].embedding
        except Exception as e:
            logger.error(f"임베딩 생성 실패: {e}")
            return []
    
    def generate_image_embedding(self, image_url: str) -> List[float]:
        """이미지 임베딩 생성 (이미지를 텍스트로 설명 후 임베딩)"""
        try:
            # 먼저 이미지를 설명으로 변환
            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": "이 이미지의 음식을 자세히 설명해주세요. 음식의 종류, 색깔, 모양, 재료 등을 포함해서 설명해주세요."
                            },
                            {
                                "type": "image_url",
                                "image_url": {"url": image_url}
                            }
                        ]
                    }
                ],
                max_tokens=200,
                temperature=0.1
            )
            
            description = response.choices[0].message.content.strip()
            
            # 설명을 임베딩으로 변환
            return self.generate_embedding(description)
            
        except Exception as e:
            logger.error(f"이미지 임베딩 생성 실패: {e}")
            return []
    
    def crop_food_items(self, image_url: str, detected_foods: List[Dict]) -> List[str]:
        """음식 아이템별로 이미지 크롭 (실제로는 bbox 정보만 반환)"""
        # 실제 구현에서는 이미지 처리 라이브러리를 사용하여 크롭
        # 여기서는 간단히 bbox 정보를 기반으로 크롭된 이미지 URL을 생성한다고 가정
        cropped_urls = []
        
        for i, food in enumerate(detected_foods):
            # 실제로는 이미지를 다운로드하고 크롭한 후 S3에 업로드
            # 여기서는 예시로 원본 URL을 반환
            cropped_urls.append(f"{image_url}#crop_{i}")
        
        return cropped_urls
