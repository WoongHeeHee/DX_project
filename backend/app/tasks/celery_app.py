"""
Celery 애플리케이션 설정
"""

from celery import Celery
from app.config import settings

# Celery 앱 생성
celery_app = Celery(
    "market_explorer",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        "app.tasks.photo_tasks",
        "app.tasks.recommendation_tasks",
        "app.tasks.maintenance_tasks"
    ]
)

# Celery 설정
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30분
    task_soft_time_limit=25 * 60,  # 25분
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,
)

# 주기적 작업 스케줄
celery_app.conf.beat_schedule = {
    # 추천 시스템 업데이트 (매일 새벽 2시)
    'update-recommendations': {
        'task': 'app.tasks.recommendation_tasks.update_collaborative_filtering',
        'schedule': 60.0 * 60.0 * 24.0,  # 24시간마다
    },
    # 키워드 리뷰 집계 (매시간)
    'aggregate-keyword-reviews': {
        'task': 'app.tasks.maintenance_tasks.aggregate_keyword_reviews',
        'schedule': 60.0 * 60.0,  # 1시간마다
    },
    # 오래된 사진 정리 (매일)
    'cleanup-old-photos': {
        'task': 'app.tasks.maintenance_tasks.cleanup_old_photos',
        'schedule': 60.0 * 60.0 * 24.0,  # 24시간마다
    },
}
