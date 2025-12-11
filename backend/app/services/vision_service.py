"""
OpenAI Vision API 서비스
bbox 탐지 전용 서비스

역할:
- detect_foods_with_bbox(): 여러 음식 탐지 및 bbox 반환
- 메뉴 매칭은 menu_matcher_service.py가 담당 (단일 진실 소스)
"""

import json
import logging
from typing import List, Dict, Any, Optional

from app.services.openai_service import OpenAIService

logger = logging.getLogger(__name__)


class VisionService:
    """OpenAI Vision API 서비스 - bbox 탐지 전용"""
    
    def __init__(self):
        self.openai_service = OpenAIService()
    
    def detect_foods_with_bbox(
        self,
        image_url: str,
        menu_candidates: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        이미지에서 여러 음식을 탐지하고 bounding box 반환
        
        이 함수는 bbox만 반환하며, 메뉴 매칭은 menu_matcher_service.py가 담당합니다.
        
        Args:
            image_url: presigned URL 또는 공개 URL
            menu_candidates: 가능한 메뉴 목록 (선택, bbox 탐지 시 참고용)
        
        Returns:
            [
                {
                    "bbox": [x1, y1, x2, y2],  # 0~1 정규화
                    "candidates": ["menu1", "menu2"],  # 가능성 높은 메뉴 1~3개 (참고용)
                    "confidence": 0.0~1.0
                }
            ]
        """
        menu_list_str = ""
        if menu_candidates:
            menu_list_str = f"\n가능한 메뉴 목록: {', '.join(menu_candidates)}"
        
        prompt = f"""이미지에서 여러 음식을 탐지하고 각각에 대해 분석해주세요.{menu_list_str}

각 음식에 대해:
1. 바운딩 박스 좌표 (x1, y1, x2, y2) - 0~1 사이의 정규화된 값
2. 가능한 메뉴 이름 1~3개 (위 목록에서 선택하거나 추정) - 참고용
3. 신뢰도 (0.0~1.0)

JSON 배열로 응답해주세요:
[
    {{
        "bbox": [x1, y1, x2, y2],
        "candidates": ["menu1", "menu2"],
        "confidence": 0.0~1.0
    }}
]

중요: candidates는 참고용이며, 최종 메뉴 매칭은 별도로 수행됩니다."""
        
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
                max_tokens=1000,
                temperature=0.1
            )
            
            result = json.loads(response.choices[0].message.content.strip())
            
            # 유효성 검증
            valid_results = []
            for item in result:
                if "bbox" in item and "candidates" in item:
                    bbox = item["bbox"]
                    if len(bbox) == 4 and all(0 <= val <= 1 for val in bbox):
                        valid_results.append(item)
            
            logger.info(f"탐지된 음식 수: {len(valid_results)}")
            return valid_results
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON 파싱 오류: {e}, 응답: {response.choices[0].message.content if 'response' in locals() else 'N/A'}")
            return []
        except Exception as e:
            error_msg = str(e)
            # OpenAI의 invalid_image_url 에러 감지
            if "invalid_image_url" in error_msg.lower() or "timeout" in error_msg.lower():
                logger.error(f"OpenAI Vision API 이미지 다운로드 실패: {error_msg}, image_url={image_url[:100]}...")
            else:
                logger.error(f"음식 탐지 중 오류 발생: {e}", exc_info=True)
            return []
