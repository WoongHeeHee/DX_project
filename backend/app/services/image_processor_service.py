"""
이미지 처리 서비스
기존 src/image_processor.py를 backend 구조에 맞게 통합
"""

import json
import logging
from typing import Dict, List, Optional
from sqlalchemy.orm import Session

from app.services.openai_service import OpenAIService
from app.services.menu_matcher_service import MenuMatcherService

logger = logging.getLogger(__name__)


class ImageProcessorService:
    """
    통합 이미지 처리 시스템
    3가지 케이스를 모두 처리:
    1. 비회원 가게 영업사진 업로드
    2. 회원 음식 검색
    3. 회원 음식 발자취(리뷰)
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.openai_service = OpenAIService()
        self.menu_matcher = MenuMatcherService(db)
    
    def classify_food_image(self, image_url: str) -> Dict:
        """
        음식 사진 분류 (40% 기준)
        
        Args:
            image_url: 분석할 이미지 URL
        
        Returns:
            {
                "is_food": bool,
                "coverage": float (0.0-1.0),
                "food_count": int
            }
        """
        prompt = """
        이미지를 분석하여 다음을 판별해주세요:
        1. 음식이 전체 사진 면적의 40% 이상을 차지하는가?
        2. 음식의 개수는 몇 개인가?
        
        JSON 형태로 응답해주세요:
        {
            "is_food": true/false,
            "coverage": 0.0-1.0,
            "food_count": 숫자
        }
        """
        
        try:
            response = self.openai_service.client.chat.completions.create(
                model="gpt-4o",
                messages=[{
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": image_url}}
                    ]
                }],
                max_tokens=150,
                temperature=0.1
            )
            
            result = json.loads(response.choices[0].message.content.strip())
            return result
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON 파싱 오류: {e}")
            return {"is_food": False, "coverage": 0.0, "food_count": 0}
        except Exception as e:
            logger.error(f"음식 분류 중 오류 발생: {e}")
            return {"is_food": False, "coverage": 0.0, "food_count": 0}
    
    def detect_multiple_foods(self, image_url: str) -> List[Dict]:
        """
        여러 음식 탐지 및 bbox 생성
        
        Args:
            image_url: 분석할 이미지 URL
        
        Returns:
            [
                {
                    "menu": str,
                    "bbox": [x1, y1, x2, y2],
                    "confidence": float
                }
            ]
        """
        menus = self.menu_matcher.get_all_menus()
        menu_list = ', '.join(menus)
        
        prompt = f"""
        이미지에서 여러 음식을 탐지하고 각각에 대해 분석해주세요.
        
        가능한 메뉴 목록: {menu_list}
        
        각 음식에 대해:
        1. 바운딩 박스 좌표 (x1, y1, x2, y2) - 0~1 사이의 정규화된 값
        2. 메뉴 분류 (위 목록에서만 선택)
        3. 신뢰도
        
        JSON 배열로 응답해주세요:
        [
            {{
                "menu": "메뉴명",
                "bbox": [x1, y1, x2, y2],
                "confidence": 0.0-1.0
            }}
        ]
        """
        
        try:
            response = self.openai_service.client.chat.completions.create(
                model="gpt-4o",
                messages=[{
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": image_url}}
                    ]
                }],
                max_tokens=500,
                temperature=0.1
            )
            
            result = json.loads(response.choices[0].message.content.strip())
            
            # 메뉴 유효성 검증
            valid_results = []
            for item in result:
                if item.get("menu") in menus:
                    valid_results.append(item)
            
            return valid_results
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON 파싱 오류: {e}")
            return []
        except Exception as e:
            logger.error(f"다중 음식 탐지 중 오류 발생: {e}")
            return []
    
    def validate_store_photo(self, image_url: str) -> bool:
        """
        가게 사진 적합성 판별
        
        Args:
            image_url: 검증할 이미지 URL
        
        Returns:
            적합하면 True, 부적합하면 False
        """
        prompt = """
        이 사진이 회원에게 보여줄 가게 사진으로 적합한지 판별해주세요.
        
        부적합한 경우:
        - 사람 얼굴이 큰 비중을 차지하는 사진
        - 바닥만 찍힌 사진
        - 흔들린 사진
        - 가게와 관련없는 사진
        - 음식이 아닌 다른 물체가 주를 이루는 사진
        
        적합하면 "true", 부적합하면 "false"만 응답하세요.
        """
        
        try:
            response = self.openai_service.client.chat.completions.create(
                model="gpt-4o",
                messages=[{
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": image_url}}
                    ]
                }],
                max_tokens=10,
                temperature=0.1
            )
            
            result = response.choices[0].message.content.strip().lower()
            return result == 'true'
            
        except Exception as e:
            logger.error(f"가게 사진 검증 중 오류 발생: {e}")
            return False
    
    def match_single_menu(self, image_url: str, user_text: Optional[str] = None) -> Optional[str]:
        """
        단일 음식 메뉴 매칭
        
        Args:
            image_url: 이미지 URL
            user_text: 사용자 설명 (선택)
        
        Returns:
            매칭된 메뉴명 또는 None
        """
        return self.menu_matcher.match_menu(image_url=image_url, user_text=user_text)
    
    def process_store_photo(self, image_url: str) -> Dict:
        """
        케이스 1: 비회원 가게 영업사진 업로드 처리
        
        Args:
            image_url: 처리할 이미지 URL
        
        Returns:
            처리 결과
        """
        # Step 1: 음식 사진 여부 판별 (55% 기준)
        food_classification = self.classify_food_image(image_url)
        
        if food_classification['is_food'] and food_classification['coverage'] > 0.55:
            # Step 2: 단일 vs 다중 음식 판별
            if food_classification['food_count'] == 1:
                # 단일 음식 태깅
                menu_tag = self.match_single_menu(image_url)
                return {
                    'type': 'single_food',
                    'menu': menu_tag,
                    'usage': 'current_market_status',
                    'classification': food_classification
                }
            else:
                # 다중 음식 객체 탐지 및 태깅
                detected_foods = self.detect_multiple_foods(image_url)
                return {
                    'type': 'multiple_foods',
                    'foods': detected_foods,
                    'usage': 'current_market_status',
                    'classification': food_classification
                }
        else:
            # Step 3: 가게 사진 적합성 판별
            is_suitable = self.validate_store_photo(image_url)
            return {
                'type': 'store_photo',
                'is_suitable': is_suitable,
                'usage': 'current_market_status' if is_suitable else 'rejected',
                'classification': food_classification
            }
    
    def process_food_search(self, image_url: str, user_prompt: Optional[str] = None) -> Dict:
        """
        케이스 2: 회원 음식 검색 처리
        
        Args:
            image_url: 검색할 이미지 URL
            user_prompt: 사용자 프롬프트 (선택)
        
        Returns:
            검색 결과
        """
        menu = self.match_single_menu(image_url, user_prompt)
        return {
            'type': 'food_search',
            'menu': menu,
            'success': menu is not None
        }
    
    def process_food_trail(self, image_urls: List[str], store_id: str) -> Dict:
        """
        케이스 3: 회원 음식 발자취(리뷰) 처리
        
        Args:
            image_urls: 처리할 이미지 URL 리스트
            store_id: 가게 ID
        
        Returns:
            발자취 처리 결과
        """
        all_detected_foods = []
        
        for i, image_url in enumerate(image_urls):
            # 각 사진에서 음식 분류
            food_classification = self.classify_food_image(image_url)
            
            if food_classification['is_food']:
                if food_classification['food_count'] == 1:
                    # 단일 음식
                    menu = self.match_single_menu(image_url)
                    if menu:
                        all_detected_foods.append({
                            'image_index': i,
                            'image_url': image_url,
                            'menu': menu,
                            'bbox': None,  # 단일 음식은 전체 이미지
                            'confidence': 1.0
                        })
                else:
                    # 다중 음식 탐지
                    detected_foods = self.detect_multiple_foods(image_url)
                    for food in detected_foods:
                        food['image_index'] = i
                        food['image_url'] = image_url
                    all_detected_foods.extend(detected_foods)
        
        return {
            'type': 'food_trail',
            'store_id': store_id,
            'detected_foods': all_detected_foods,
            'total_menu_count': len(all_detected_foods),
            'total_images': len(image_urls)
        }

