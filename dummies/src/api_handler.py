from typing import Dict, List, Optional, Union
from image_processor import ImageProcessor


class ImageAPIHandler:
    """
    통합 이미지 처리 API 핸들러
    3가지 이미지 업로드 케이스를 통합 처리
    """
    
    def __init__(self):
        self.processor = ImageProcessor()
    
    def handle_image_upload(self, image_url: str, context: Dict) -> Dict:
        """
        통합 이미지 처리 API
        
        Args:
            image_url (str): 처리할 이미지 URL
            context (Dict): 컨텍스트 정보
                {
                    'type': 'store_photo' | 'food_search' | 'food_trail',
                    'user_type': 'member' | 'non_member',
                    'store_id': str (optional, food_trail용),
                    'user_prompt': str (optional, food_search용)
                }
        
        Returns:
            Dict: 처리 결과
        """
        try:
            upload_type = context.get('type')
            
            if upload_type == 'store_photo':
                return self._handle_store_photo(image_url, context)
            elif upload_type == 'food_search':
                return self._handle_food_search(image_url, context)
            elif upload_type == 'food_trail':
                return self._handle_food_trail(image_url, context)
            else:
                return {
                    'success': False,
                    'error': f'지원하지 않는 업로드 타입: {upload_type}',
                    'supported_types': ['store_photo', 'food_search', 'food_trail']
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'이미지 처리 중 오류 발생: {str(e)}'
            }
    
    def handle_multiple_images(self, image_urls: List[str], context: Dict) -> Dict:
        """
        여러 이미지 동시 처리 (주로 food_trail용)
        
        Args:
            image_urls (List[str]): 처리할 이미지 URL 리스트
            context (Dict): 컨텍스트 정보
        
        Returns:
            Dict: 처리 결과
        """
        try:
            upload_type = context.get('type')
            
            if upload_type == 'food_trail':
                store_id = context.get('store_id')
                if not store_id:
                    return {
                        'success': False,
                        'error': 'food_trail 타입은 store_id가 필요합니다.'
                    }
                
                result = self.processor.process_food_trail(image_urls, store_id)
                return {
                    'success': True,
                    'data': result
                }
            else:
                # 다른 타입들은 개별 처리
                results = []
                for i, image_url in enumerate(image_urls):
                    result = self.handle_image_upload(image_url, context)
                    result['image_index'] = i
                    results.append(result)
                
                return {
                    'success': True,
                    'data': {
                        'type': 'multiple_individual',
                        'results': results,
                        'total_images': len(image_urls)
                    }
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'다중 이미지 처리 중 오류 발생: {str(e)}'
            }
    
    def _handle_store_photo(self, image_url: str, context: Dict) -> Dict:
        """케이스 1: 비회원 가게 영업사진 업로드 처리"""
        result = self.processor.process_store_photo(image_url)
        
        return {
            'success': True,
            'data': result,
            'context': {
                'user_type': context.get('user_type', 'non_member'),
                'purpose': '가게 영업 상태 확인'
            }
        }
    
    def _handle_food_search(self, image_url: str, context: Dict) -> Dict:
        """케이스 2: 회원 음식 검색 처리"""
        user_prompt = context.get('user_prompt')
        result = self.processor.process_food_search(image_url, user_prompt)
        
        return {
            'success': True,
            'data': result,
            'context': {
                'user_type': context.get('user_type', 'member'),
                'purpose': '음식 검색 및 식별'
            }
        }
    
    def _handle_food_trail(self, image_url: str, context: Dict) -> Dict:
        """케이스 3: 회원 음식 발자취 처리 (단일 이미지)"""
        store_id = context.get('store_id')
        if not store_id:
            return {
                'success': False,
                'error': 'food_trail 타입은 store_id가 필요합니다.'
            }
        
        # 단일 이미지를 리스트로 변환하여 처리
        result = self.processor.process_food_trail([image_url], store_id)
        
        return {
            'success': True,
            'data': result,
            'context': {
                'user_type': context.get('user_type', 'member'),
                'purpose': '음식 발자취 기록'
            }
        }


# 편의 함수들
def process_store_photo(image_url: str, user_type: str = 'non_member') -> Dict:
    """가게 사진 처리 편의 함수"""
    handler = ImageAPIHandler()
    context = {
        'type': 'store_photo',
        'user_type': user_type
    }
    return handler.handle_image_upload(image_url, context)


def search_food(image_url: str, user_prompt: Optional[str] = None) -> Dict:
    """음식 검색 편의 함수"""
    handler = ImageAPIHandler()
    context = {
        'type': 'food_search',
        'user_type': 'member',
        'user_prompt': user_prompt
    }
    return handler.handle_image_upload(image_url, context)


def record_food_trail(image_urls: Union[str, List[str]], store_id: str) -> Dict:
    """음식 발자취 기록 편의 함수"""
    handler = ImageAPIHandler()
    context = {
        'type': 'food_trail',
        'user_type': 'member',
        'store_id': store_id
    }
    
    if isinstance(image_urls, str):
        return handler.handle_image_upload(image_urls, context)
    else:
        return handler.handle_multiple_images(image_urls, context)


# 사용 예시
if __name__ == "__main__":
    # 예시 1: 가게 사진 처리
    store_result = process_store_photo("https://example.com/store.jpg")
    print("가게 사진 처리 결과:", store_result)
    
    # 예시 2: 음식 검색
    search_result = search_food("https://example.com/food.jpg", "이게 뭔 음식인가요?")
    print("음식 검색 결과:", search_result)
    
    # 예시 3: 음식 발자취 (단일)
    trail_result = record_food_trail("https://example.com/meal.jpg", "store_123")
    print("발자취 기록 결과:", trail_result)
    
    # 예시 4: 음식 발자취 (다중)
    multi_trail_result = record_food_trail([
        "https://example.com/meal1.jpg",
        "https://example.com/meal2.jpg"
    ], "store_123")
    print("다중 발자취 기록 결과:", multi_trail_result)
