"""
이미지 처리 유틸리티
Pillow를 사용한 이미지 crop 기능
"""

import logging
from typing import List, Tuple, Optional
from io import BytesIO
from PIL import Image
import tempfile

logger = logging.getLogger(__name__)


def crop_image_by_bbox(
    image_bytes: bytes,
    bbox: List[float],
    padding: int = 10
) -> Optional[bytes]:
    """
    바운딩 박스 좌표를 사용하여 이미지를 crop
    
    Args:
        image_bytes: 원본 이미지 바이트
        bbox: [x1, y1, x2, y2] (0~1 정규화된 값)
        padding: crop 영역 주변에 추가할 픽셀 수
    
    Returns:
        crop된 이미지 바이트 또는 None
    """
    try:
        # PIL로 이미지 열기
        image = Image.open(BytesIO(image_bytes))
        image_width, image_height = image.size
        
        # 정규화된 좌표를 픽셀 좌표로 변환
        x1, y1, x2, y2 = bbox
        crop_x1 = int(x1 * image_width)
        crop_y1 = int(y1 * image_height)
        crop_x2 = int(x2 * image_width)
        crop_y2 = int(y2 * image_height)
        
        # 유효성 검증 및 padding 적용
        crop_x1 = max(0, crop_x1 - padding)
        crop_y1 = max(0, crop_y1 - padding)
        crop_x2 = min(image_width, crop_x2 + padding)
        crop_y2 = min(image_height, crop_y2 + padding)
        
        # 유효한 영역인지 확인
        if crop_x2 <= crop_x1 or crop_y2 <= crop_y1:
            logger.warning(f"유효하지 않은 crop 영역: ({crop_x1}, {crop_y1}, {crop_x2}, {crop_y2})")
            return None
        
        # 이미지 crop
        cropped_image = image.crop((crop_x1, crop_y1, crop_x2, crop_y2))
        
        # JPEG 바이트로 변환
        output = BytesIO()
        cropped_image.save(output, format='JPEG', quality=90)
        output.seek(0)
        
        return output.read()
        
    except Exception as e:
        logger.error(f"이미지 crop 중 오류 발생: {e}", exc_info=True)
        return None


def validate_bbox(bbox: List[float]) -> bool:
    """
    바운딩 박스 좌표 유효성 검증
    
    Args:
        bbox: [x1, y1, x2, y2] (0~1 정규화된 값)
    
    Returns:
        유효하면 True, 아니면 False
    """
    if not bbox or len(bbox) != 4:
        return False
    
    x1, y1, x2, y2 = bbox
    
    # 0~1 범위 확인
    if not all(0 <= val <= 1 for val in [x1, y1, x2, y2]):
        return False
    
    # x2 > x1, y2 > y1 확인
    if x2 <= x1 or y2 <= y1:
        return False
    
    return True

