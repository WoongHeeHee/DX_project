"""
Pinecone 벡터 데이터베이스 서비스
"""

import pinecone
from typing import List, Dict, Any, Optional
import logging
from uuid import UUID

from app.config import settings

logger = logging.getLogger(__name__)


class PineconeService:
    """Pinecone 서비스 클래스"""
    
    def __init__(self):
        # Pinecone 초기화
        pinecone.init(
            api_key=settings.PINECONE_API_KEY,
            environment=settings.PINECONE_ENVIRONMENT
        )
        
        self.index_name = settings.PINECONE_INDEX_NAME
        
        # 인덱스 존재 확인 및 생성
        self._ensure_index_exists()
        
        # 인덱스 연결
        self.index = pinecone.Index(self.index_name)
    
    def _ensure_index_exists(self):
        """인덱스가 존재하지 않으면 생성"""
        try:
            # 기존 인덱스 목록 확인
            existing_indexes = pinecone.list_indexes()
            
            if self.index_name not in existing_indexes:
                # 인덱스 생성 (OpenAI ada-002 임베딩 차원: 1536)
                pinecone.create_index(
                    name=self.index_name,
                    dimension=1536,
                    metric="cosine"
                )
                logger.info(f"Pinecone 인덱스 '{self.index_name}' 생성됨")
            else:
                logger.info(f"Pinecone 인덱스 '{self.index_name}' 이미 존재함")
                
        except Exception as e:
            logger.error(f"Pinecone 인덱스 확인/생성 실패: {e}")
            raise
    
    def upsert_menu_embedding(
        self, 
        menu_item_id: str, 
        embedding: List[float], 
        metadata: Dict[str, Any]
    ) -> bool:
        """메뉴 아이템 임베딩 업서트"""
        try:
            vector_data = {
                "id": f"menu_{menu_item_id}",
                "values": embedding,
                "metadata": {
                    "type": "menu_item",
                    "menu_item_id": menu_item_id,
                    **metadata
                }
            }
            
            self.index.upsert([vector_data])
            return True
            
        except Exception as e:
            logger.error(f"메뉴 임베딩 업서트 실패: {e}")
            return False
    
    def upsert_photo_embedding(
        self, 
        photo_id: str, 
        crop_index: int, 
        embedding: List[float], 
        metadata: Dict[str, Any]
    ) -> bool:
        """사진 크롭 임베딩 업서트"""
        try:
            vector_data = {
                "id": f"photo_{photo_id}_crop_{crop_index}",
                "values": embedding,
                "metadata": {
                    "type": "photo_crop",
                    "photo_id": photo_id,
                    "crop_index": crop_index,
                    **metadata
                }
            }
            
            self.index.upsert([vector_data])
            return True
            
        except Exception as e:
            logger.error(f"사진 임베딩 업서트 실패: {e}")
            return False
    
    def search_similar_menus(
        self, 
        query_embedding: List[float], 
        top_k: int = 10,
        filter_dict: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """유사한 메뉴 검색"""
        try:
            # 메뉴 아이템만 검색하도록 필터 설정
            search_filter = {"type": "menu_item"}
            if filter_dict:
                search_filter.update(filter_dict)
            
            results = self.index.query(
                vector=query_embedding,
                top_k=top_k,
                include_metadata=True,
                filter=search_filter
            )
            
            return [
                {
                    "menu_item_id": match.metadata.get("menu_item_id"),
                    "score": match.score,
                    "metadata": match.metadata
                }
                for match in results.matches
            ]
            
        except Exception as e:
            logger.error(f"유사 메뉴 검색 실패: {e}")
            return []
    
    def search_similar_photos(
        self, 
        query_embedding: List[float], 
        top_k: int = 10,
        filter_dict: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """유사한 사진 검색"""
        try:
            # 사진 크롭만 검색하도록 필터 설정
            search_filter = {"type": "photo_crop"}
            if filter_dict:
                search_filter.update(filter_dict)
            
            results = self.index.query(
                vector=query_embedding,
                top_k=top_k,
                include_metadata=True,
                filter=search_filter
            )
            
            return [
                {
                    "photo_id": match.metadata.get("photo_id"),
                    "crop_index": match.metadata.get("crop_index"),
                    "score": match.score,
                    "metadata": match.metadata
                }
                for match in results.matches
            ]
            
        except Exception as e:
            logger.error(f"유사 사진 검색 실패: {e}")
            return []
    
    def delete_vectors(self, vector_ids: List[str]) -> bool:
        """벡터 삭제"""
        try:
            self.index.delete(ids=vector_ids)
            return True
        except Exception as e:
            logger.error(f"벡터 삭제 실패: {e}")
            return False
    
    def delete_photo_vectors(self, photo_id: str) -> bool:
        """특정 사진의 모든 벡터 삭제"""
        try:
            # photo_id로 시작하는 모든 벡터 삭제
            self.index.delete(filter={"photo_id": photo_id})
            return True
        except Exception as e:
            logger.error(f"사진 벡터 삭제 실패: {e}")
            return False
    
    def get_index_stats(self) -> Dict[str, Any]:
        """인덱스 통계 정보 조회"""
        try:
            stats = self.index.describe_index_stats()
            return {
                "total_vector_count": stats.total_vector_count,
                "dimension": stats.dimension,
                "index_fullness": stats.index_fullness
            }
        except Exception as e:
            logger.error(f"인덱스 통계 조회 실패: {e}")
            return {}
    
    def batch_upsert_menu_embeddings(self, menu_embeddings: List[Dict[str, Any]]) -> bool:
        """메뉴 임베딩 배치 업서트"""
        try:
            vectors = []
            for item in menu_embeddings:
                vector_data = {
                    "id": f"menu_{item['menu_item_id']}",
                    "values": item['embedding'],
                    "metadata": {
                        "type": "menu_item",
                        "menu_item_id": item['menu_item_id'],
                        **item.get('metadata', {})
                    }
                }
                vectors.append(vector_data)
            
            # 배치 크기로 나누어 업서트 (Pinecone 제한: 100개씩)
            batch_size = 100
            for i in range(0, len(vectors), batch_size):
                batch = vectors[i:i + batch_size]
                self.index.upsert(batch)
            
            return True
            
        except Exception as e:
            logger.error(f"메뉴 임베딩 배치 업서트 실패: {e}")
            return False
