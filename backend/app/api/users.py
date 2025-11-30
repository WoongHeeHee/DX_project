"""
사용자 관리 API 엔드포인트
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import User
from app.models.schemas import User as UserSchema, UserUpdate, BaseResponse
from app.api.auth import get_current_user

router = APIRouter()


@router.get("/profile", response_model=UserSchema)
async def get_user_profile(current_user: User = Depends(get_current_user)):
    """사용자 프로필 조회"""
    return current_user


@router.put("/profile", response_model=UserSchema)
async def update_user_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """사용자 프로필 업데이트"""
    
    # 업데이트할 필드만 적용
    update_data = user_update.dict(exclude_unset=True)
    
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    
    return current_user


@router.post("/onboarding", response_model=UserSchema)
async def complete_onboarding(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """온보딩 완료 (프로필 설정)"""
    
    # 필수 온보딩 정보 확인
    required_fields = ['country', 'birth_yyyy_mm', 'spice_level', 'adventure', 'korean_experience']
    update_data = user_update.dict(exclude_unset=True)
    
    missing_fields = [field for field in required_fields if field not in update_data]
    if missing_fields:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"온보딩에 필요한 정보가 누락되었습니다: {', '.join(missing_fields)}"
        )
    
    # 프로필 업데이트
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    
    return current_user


@router.delete("/account", response_model=BaseResponse)
async def delete_user_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """사용자 계정 삭제"""
    
    # 사용자와 관련된 데이터 정리 (실제로는 더 복잡한 로직 필요)
    # 사진의 uploader_user_id를 NULL로 설정 (익명화)
    from app.db.models import Photo
    db.query(Photo).filter(Photo.uploader_user_id == current_user.id).update(
        {Photo.uploader_user_id: None}
    )
    
    # 사용자 삭제
    db.delete(current_user)
    db.commit()
    
    return BaseResponse(
        success=True,
        message="계정이 성공적으로 삭제되었습니다"
    )


@router.get("/preferences", response_model=dict)
async def get_user_preferences(current_user: User = Depends(get_current_user)):
    """사용자 선호도 정보 조회"""
    return {
        "spice_level": current_user.spice_level,
        "adventure": current_user.adventure,
        "korean_experience": current_user.korean_experience,
        "locale": current_user.locale,
        "country": current_user.country
    }
