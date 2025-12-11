"""
다이어리 관련 API 엔드포인트
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import User, Diary, Like, Photo, Market, Shop, MenuItem
from app.models.schemas import (
    DiaryCreate,
    Diary as DiarySchema,
    LikeCreate,
    BaseResponse
)
from app.api.auth import get_current_user
from typing import List, Dict, Any

router = APIRouter()


@router.post("/", response_model=DiarySchema)
async def create_diary(
    diary_data: DiaryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """다이어리 생성"""
    try:
        # 시장 존재 확인
        market = db.query(Market).filter(Market.id == diary_data.market_id).first()
        if not market:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시장을 찾을 수 없습니다"
            )
        
        # 사진 ID 유효성 검증
        if diary_data.photo_ids:
            valid_photos = db.query(Photo).filter(
                Photo.id.in_(diary_data.photo_ids),
                Photo.uploader_user_id == current_user.id
            ).count()
            
            if valid_photos != len(diary_data.photo_ids):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="일부 사진에 대한 권한이 없습니다"
                )
        
        # 키워드 검증 (최소 1개 필요)
        if not diary_data.keywords or len(diary_data.keywords) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="최소 하나의 키워드를 선택해주세요"
            )
        
        # 다이어리 생성
        diary = Diary(
            user_id=current_user.id,
            market_id=diary_data.market_id,
            content=diary_data.content,
            photo_ids=diary_data.photo_ids,
            keywords=diary_data.keywords
        )
        
        db.add(diary)
        db.commit()
        db.refresh(diary)
        
        # 키워드 리뷰 업데이트 (시장별 키워드 저장)
        if diary_data.keywords:
            from app.tasks.maintenance_tasks import update_keyword_reviews
            from app.db.models import KeywordReview
            from datetime import datetime, timezone
            
            # 즉시 업데이트 (비동기 대신)
            for keyword in diary_data.keywords:
                existing_review = db.query(KeywordReview).filter(
                    KeywordReview.market_id == diary_data.market_id,
                    KeywordReview.keyword == keyword
                ).first()
                
                if existing_review:
                    existing_review.count += 1
                    existing_review.last_updated = datetime.now(timezone.utc)
                else:
                    new_review = KeywordReview(
                        market_id=diary_data.market_id,
                        keyword=keyword,
                        count=1
                    )
                    db.add(new_review)
            
            db.commit()
        
        # 이벤트 기록
        from app.db.models import Event, ActionType, TargetType
        event = Event(
            user_id=current_user.id,
            action_type=ActionType.DIARY_CREATE,
            target_type=TargetType.DIARY,
            target_id=diary.id
        )
        db.add(event)
        db.commit()
        
        return DiarySchema.model_validate(diary)
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"다이어리 생성 실패: {str(e)}"
        )


@router.get("/my", response_model=List[DiarySchema])
async def get_my_diaries(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 20,
    offset: int = 0
):
    """내 다이어리 목록 조회"""
    diaries = db.query(Diary).filter(
        Diary.user_id == current_user.id
    ).order_by(Diary.created_at.desc()).offset(offset).limit(limit).all()
    
    return diaries


@router.get("/{diary_id}", response_model=DiarySchema)
async def get_diary(
    diary_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """특정 다이어리 조회"""
    diary = db.query(Diary).filter(
        Diary.id == diary_id,
        Diary.user_id == current_user.id
    ).first()
    
    if not diary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="다이어리를 찾을 수 없습니다"
        )
    
    return diary


@router.put("/{diary_id}", response_model=DiarySchema)
async def update_diary(
    diary_id: str,
    diary_update: DiaryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """다이어리 수정"""
    diary = db.query(Diary).filter(
        Diary.id == diary_id,
        Diary.user_id == current_user.id
    ).first()
    
    if not diary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="다이어리를 찾을 수 없습니다"
        )
    
    try:
        # 업데이트
        diary.content = diary_update.content
        diary.photo_ids = diary_update.photo_ids
        diary.keywords = diary_update.keywords
        
        db.commit()
        db.refresh(diary)
        
        return DiarySchema.model_validate(diary)
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"다이어리 수정 실패: {str(e)}"
        )


@router.delete("/{diary_id}", response_model=BaseResponse)
async def delete_diary(
    diary_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """다이어리 삭제"""
    diary = db.query(Diary).filter(
        Diary.id == diary_id,
        Diary.user_id == current_user.id
    ).first()
    
    if not diary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="다이어리를 찾을 수 없습니다"
        )
    
    try:
        db.delete(diary)
        db.commit()
        
        return BaseResponse(
            success=True,
            message="다이어리가 성공적으로 삭제되었습니다"
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"다이어리 삭제 실패: {str(e)}"
        )


@router.post("/likes", response_model=BaseResponse)
async def create_like(
    like_data: LikeCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """메뉴 좋아요"""
    try:
        # 이미 좋아요했는지 확인
        existing_like = db.query(Like).filter(
            Like.user_id == current_user.id,
            Like.menu_item_id == like_data.menu_item_id
        ).first()
        
        if existing_like:
            return BaseResponse(
                success=True,
                message="이미 좋아요한 메뉴입니다"
            )
        
        # 좋아요 생성
        like = Like(
            user_id=current_user.id,
            menu_item_id=like_data.menu_item_id
        )
        
        db.add(like)
        
        # 이벤트 기록
        from app.db.models import Event, ActionType, TargetType
        event = Event(
            user_id=current_user.id,
            action_type=ActionType.LIKE,
            target_type=TargetType.MENU_ITEM,
            target_id=like_data.menu_item_id
        )
        db.add(event)
        
        db.commit()
        
        return BaseResponse(
            success=True,
            message="좋아요가 추가되었습니다"
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"좋아요 추가 실패: {str(e)}"
        )


@router.delete("/likes/{menu_item_id}", response_model=BaseResponse)
async def remove_like(
    menu_item_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """좋아요 취소"""
    like = db.query(Like).filter(
        Like.user_id == current_user.id,
        Like.menu_item_id == menu_item_id
    ).first()
    
    if not like:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="좋아요를 찾을 수 없습니다"
        )
    
    try:
        db.delete(like)
        db.commit()
        
        return BaseResponse(
            success=True,
            message="좋아요가 취소되었습니다"
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"좋아요 취소 실패: {str(e)}"
        )


@router.get("/my-likes")
async def get_my_likes(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 20,
    offset: int = 0
):
    """내 좋아요 목록"""
    from app.db.models import MenuItem
    
    likes = db.query(MenuItem).join(Like).filter(
        Like.user_id == current_user.id
    ).order_by(Like.created_at.desc()).offset(offset).limit(limit).all()
    
    return likes


@router.get("/market-photos/{market_id}")
async def get_market_photos(
    market_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> List[Dict[str, Any]]:
    """
    시장별 사용자 사진 조회 (다이어리 작성용)
    
    특정 시장의 가게들에 속한 사용자 사진을 조회합니다.
    사진은 menu_item_id가 있는 것만 반환합니다 (메뉴 인식 완료된 것).
    """
    try:
        # 시장 존재 확인
        market = db.query(Market).filter(Market.id == market_id).first()
        if not market:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시장을 찾을 수 없습니다"
            )
        
        # 시장 내 가게들 조회
        shops = db.query(Shop).filter(Shop.market_id == market_id).all()
        shop_ids = [shop.id for shop in shops]
        
        if not shop_ids:
            return []
        
        # 해당 시장의 가게들에 속한 사용자 사진 조회
        # menu_item_id가 있는 것만 (메뉴 인식 완료된 것)
        photos = db.query(Photo).filter(
            Photo.uploader_user_id == current_user.id,
            Photo.shop_id.in_(shop_ids),
            Photo.menu_item_id.isnot(None),
            Photo.processed == True
        ).order_by(Photo.taken_at.desc()).all()
        
        # CDN URL 생성 헬퍼 함수
        def s3_key_to_cdn_url(s3_key: str) -> str:
            if not s3_key:
                return ""
            cdn_base_url = "https://dnzeuzpu74ulj.cloudfront.net"
            if s3_key.startswith('http://') or s3_key.startswith('https://'):
                return s3_key
            return f"{cdn_base_url}/{s3_key}"
        
        # 메뉴 정보 포함하여 반환
        result = []
        for photo in photos:
            menu_item = db.query(MenuItem).filter(MenuItem.id == photo.menu_item_id).first()
            if menu_item:
                # 좋아요 여부 확인
                like = db.query(Like).filter(
                    Like.user_id == current_user.id,
                    Like.menu_item_id == photo.menu_item_id
                ).first()
                
                result.append({
                    "id": photo.id,
                    "photo_url": s3_key_to_cdn_url(photo.thumbnail_s3_key or photo.s3_key),
                    "recognized_menu_name": menu_item.name_en or menu_item.name,
                    "menu_item_id": photo.menu_item_id,  # 좋아요 API 호출용
                    "is_liked": like is not None
                })
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"시장별 사진 조회 실패: {str(e)}"
        )


