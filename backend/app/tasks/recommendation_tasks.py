"""
추천 시스템 관련 Celery 작업
"""

import logging
import numpy as np
from scipy.sparse import csr_matrix
from implicit.als import AlternatingLeastSquares
from typing import Dict, List, Tuple

from app.tasks.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task
def update_collaborative_filtering():
    """협업 필터링 모델 업데이트"""
    try:
        logger.info("협업 필터링 모델 업데이트 시작")
        
        from app.db.database import SessionLocal
        from app.db.models import User, MenuItem, Like
        from app.config import settings
        import redis
        import pickle
        
        db = SessionLocal()
        redis_client = redis.from_url(settings.REDIS_URL)
        
        try:
            # 사용자-아이템 상호작용 데이터 수집
            likes = db.query(Like).all()
            
            if len(likes) < 10:  # 최소 데이터 요구사항
                logger.warning("협업 필터링을 위한 충분한 데이터가 없습니다")
                return
            
            # 사용자 및 아이템 매핑 생성
            user_ids = list(set(like.user_id for like in likes))
            item_ids = list(set(like.menu_item_id for like in likes))
            
            user_to_idx = {user_id: idx for idx, user_id in enumerate(user_ids)}
            item_to_idx = {item_id: idx for idx, item_id in enumerate(item_ids)}
            
            # 상호작용 행렬 생성
            rows, cols, data = [], [], []
            for like in likes:
                user_idx = user_to_idx[like.user_id]
                item_idx = item_to_idx[like.menu_item_id]
                rows.append(user_idx)
                cols.append(item_idx)
                data.append(1.0)  # 암시적 피드백 (좋아요 = 1)
            
            # 희소 행렬 생성
            interaction_matrix = csr_matrix(
                (data, (rows, cols)), 
                shape=(len(user_ids), len(item_ids))
            )
            
            # ALS 모델 훈련
            model = AlternatingLeastSquares(
                factors=settings.RECOMMENDATION_FACTORS,
                regularization=0.1,
                iterations=20,
                alpha=settings.RECOMMENDATION_ALPHA
            )
            
            model.fit(interaction_matrix)
            
            # 모델과 매핑 정보를 Redis에 저장
            model_data = {
                'model': model,
                'user_to_idx': user_to_idx,
                'item_to_idx': item_to_idx,
                'idx_to_user': {idx: user_id for user_id, idx in user_to_idx.items()},
                'idx_to_item': {idx: item_id for item_id, idx in item_to_idx.items()},
                'interaction_matrix': interaction_matrix
            }
            
            # Redis에 저장 (24시간 TTL)
            redis_client.setex(
                'cf_model', 
                86400,  # 24시간
                pickle.dumps(model_data)
            )
            
            logger.info(f"협업 필터링 모델 업데이트 완료 - 사용자: {len(user_ids)}, 아이템: {len(item_ids)}")
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"협업 필터링 모델 업데이트 실패: {e}")
        raise


@celery_app.task
def generate_user_recommendations(user_id: str, limit: int = 10):
    """특정 사용자를 위한 추천 생성"""
    try:
        logger.info(f"사용자 {user_id}를 위한 추천 생성 시작")
        
        from app.config import settings
        import redis
        import pickle
        
        redis_client = redis.from_url(settings.REDIS_URL)
        
        # Redis에서 모델 로드
        model_data = redis_client.get('cf_model')
        if not model_data:
            logger.warning("협업 필터링 모델이 없습니다. 모델을 먼저 훈련하세요.")
            return []
        
        model_data = pickle.loads(model_data)
        model = model_data['model']
        user_to_idx = model_data['user_to_idx']
        idx_to_item = model_data['idx_to_item']
        interaction_matrix = model_data['interaction_matrix']
        
        # 사용자 인덱스 확인
        if user_id not in user_to_idx:
            logger.warning(f"사용자 {user_id}가 모델에 없습니다")
            return []
        
        user_idx = user_to_idx[user_id]
        
        # 추천 생성
        recommendations = model.recommend(
            user_idx, 
            interaction_matrix[user_idx], 
            N=limit,
            filter_already_liked_items=True
        )
        
        # 결과 변환
        recommended_items = []
        for item_idx, score in recommendations:
            item_id = idx_to_item[item_idx]
            recommended_items.append({
                'menu_item_id': item_id,
                'score': float(score)
            })
        
        # Redis에 사용자별 추천 결과 저장 (1시간 TTL)
        redis_client.setex(
            f'user_recommendations:{user_id}',
            3600,  # 1시간
            pickle.dumps(recommended_items)
        )
        
        logger.info(f"사용자 {user_id}를 위한 추천 {len(recommended_items)}개 생성 완료")
        return recommended_items
        
    except Exception as e:
        logger.error(f"사용자 추천 생성 실패: {e}")
        return []


@celery_app.task
def calculate_item_similarities():
    """아이템 간 유사도 계산"""
    try:
        logger.info("아이템 유사도 계산 시작")
        
        from app.db.database import SessionLocal
        from app.db.models import MenuItem, Like
        from sklearn.metrics.pairwise import cosine_similarity
        from app.config import settings
        import redis
        import pickle
        
        db = SessionLocal()
        redis_client = redis.from_url(settings.REDIS_URL)
        
        try:
            # 모든 메뉴 아이템과 좋아요 데이터 수집
            menu_items = db.query(MenuItem).all()
            likes = db.query(Like).all()
            
            if len(menu_items) < 2:
                logger.warning("유사도 계산을 위한 충분한 아이템이 없습니다")
                return
            
            # 아이템-사용자 행렬 생성
            item_to_idx = {str(item.id): idx for idx, item in enumerate(menu_items)}
            user_ids = list(set(str(like.user_id) for like in likes))
            
            # 아이템별 사용자 벡터 생성
            item_vectors = np.zeros((len(menu_items), len(user_ids)))
            user_to_idx = {user_id: idx for idx, user_id in enumerate(user_ids)}
            
            for like in likes:
                item_idx = item_to_idx.get(str(like.menu_item_id))
                user_idx = user_to_idx.get(str(like.user_id))
                if item_idx is not None and user_idx is not None:
                    item_vectors[item_idx][user_idx] = 1.0
            
            # 코사인 유사도 계산
            similarity_matrix = cosine_similarity(item_vectors)
            
            # 각 아이템별 유사한 아이템 저장
            item_similarities = {}
            for i, item in enumerate(menu_items):
                # 자기 자신을 제외한 유사도 높은 아이템들
                similar_indices = np.argsort(similarity_matrix[i])[::-1][1:11]  # 상위 10개
                similar_items = []
                
                for j in similar_indices:
                    if similarity_matrix[i][j] > 0.1:  # 최소 유사도 임계값
                        similar_items.append({
                            'menu_item_id': str(menu_items[j].id),
                            'similarity': float(similarity_matrix[i][j])
                        })
                
                item_similarities[str(item.id)] = similar_items
            
            # Redis에 저장
            redis_client.setex(
                'item_similarities',
                86400,  # 24시간
                pickle.dumps(item_similarities)
            )
            
            logger.info(f"아이템 유사도 계산 완료 - {len(item_similarities)}개 아이템")
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"아이템 유사도 계산 실패: {e}")
        raise


@celery_app.task
def update_popularity_scores():
    """인기도 점수 업데이트"""
    try:
        logger.info("인기도 점수 업데이트 시작")
        
        from app.db.database import SessionLocal
        from app.db.models import MenuItem, Like, Pin
        from datetime import datetime, timedelta
        from app.config import settings
        import redis
        import pickle
        
        db = SessionLocal()
        redis_client = redis.from_url(settings.REDIS_URL)
        
        try:
            # 최근 활동에 가중치 부여
            now = datetime.utcnow()
            week_ago = now - timedelta(days=7)
            month_ago = now - timedelta(days=30)
            
            menu_items = db.query(MenuItem).all()
            popularity_scores = {}
            
            for item in menu_items:
                # 최근 1주일 좋아요 (가중치 1.0)
                recent_likes = db.query(Like).filter(
                    Like.menu_item_id == item.id,
                    Like.created_at >= week_ago
                ).count()
                
                # 최근 1개월 좋아요 (가중치 0.5)
                month_likes = db.query(Like).filter(
                    Like.menu_item_id == item.id,
                    Like.created_at >= month_ago,
                    Like.created_at < week_ago
                ).count()
                
                # 전체 좋아요 (가중치 0.2)
                total_likes = db.query(Like).filter(
                    Like.menu_item_id == item.id,
                    Like.created_at < month_ago
                ).count()
                
                # 핀 수 (가중치 0.3)
                pin_count = db.query(Pin).filter(
                    Pin.menu_item_id == item.id
                ).count()
                
                # 인기도 점수 계산
                popularity_score = (
                    recent_likes * 1.0 +
                    month_likes * 0.5 +
                    total_likes * 0.2 +
                    pin_count * 0.3
                )
                
                # 스무딩 적용
                smoothed_score = (popularity_score + settings.RECOMMENDATION_ALPHA) / (1 + settings.RECOMMENDATION_ALPHA)
                
                popularity_scores[str(item.id)] = {
                    'score': smoothed_score,
                    'recent_likes': recent_likes,
                    'total_likes': recent_likes + month_likes + total_likes,
                    'pin_count': pin_count
                }
            
            # Redis에 저장
            redis_client.setex(
                'popularity_scores',
                3600,  # 1시간
                pickle.dumps(popularity_scores)
            )
            
            logger.info(f"인기도 점수 업데이트 완료 - {len(popularity_scores)}개 아이템")
            
        finally:
            db.close()
            
    except Exception as e:
        logger.error(f"인기도 점수 업데이트 실패: {e}")
        raise
