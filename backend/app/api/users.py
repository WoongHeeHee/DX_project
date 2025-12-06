"""
사용자 관리 API 엔드포인트
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import User, AdventureLevel, KoreanExperience
from app.models.schemas import (
    User as UserSchema, 
    UserUpdate, 
    BaseResponse,
    KoreanNameGenerateRequest,
    KoreanNameGenerateResponse
)
from app.api.auth import get_current_user, get_optional_user
from app.services.korean_name_service import KoreanNameService

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
@router.put("/complete-onboarding", response_model=UserSchema)
async def complete_onboarding(
    user_update: UserUpdate,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db)
):
    """
    온보딩 완료 (프로필 설정) - 인증 선택적
    
    온보딩 단계에서 인증 없이도 사용 가능하도록 구현.
    인증된 사용자의 경우 current_user가 설정되고,
    인증되지 않은 경우 임시 사용자를 생성하거나 에러를 반환할 수 있습니다.
    
    주의: 실제 운영 환경에서는 인증이 필요할 수 있습니다.
    """
    # 필수 온보딩 정보 확인
    required_fields = ['country', 'birth_yyyy_mm', 'spice_level', 'adventure', 'korean_experience']
    update_data = user_update.dict(exclude_unset=True)
    
    missing_fields = [field for field in required_fields if field not in update_data]
    if missing_fields:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"온보딩에 필요한 정보가 누락되었습니다: {', '.join(missing_fields)}"
        )
    
    # 인증되지 않은 경우 처리 (기능 실험용)
    # TODO: 실제 운영 환경에서는 인증이 필요하도록 수정
    if current_user is None:
        # 임시 사용자 생성 (기능 실험용)
        # 실제 운영 환경에서는 인증이 필요하도록 변경해야 합니다
        try:
            current_user = User(
                google_id=None,  # 임시 사용자
                email=None,
                display_name="임시 사용자",
                locale=update_data.get('locale', 'ko'),
                adventure=AdventureLevel.MODERATE,
                korean_experience=KoreanExperience.FIRST_TIME,
            )
            db.add(current_user)
            db.commit()
            db.refresh(current_user)
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"임시 사용자 생성 실패: {str(e)}"
            )
    
    # 프로필 업데이트
    for field, value in update_data.items():
        # Enum 필드는 문자열을 Enum으로 변환
        if field == 'adventure' and isinstance(value, str):
            try:
                value = AdventureLevel(value)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"잘못된 adventure 값: {value}"
                )
        elif field == 'korean_experience' and isinstance(value, str):
            try:
                value = KoreanExperience(value)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"잘못된 korean_experience 값: {value}"
                )
        setattr(current_user, field, value)
    
    # 온보딩 완료 플래그 설정
    current_user.onboarding_completed = True
    
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


@router.post("/generate-korean-name", response_model=KoreanNameGenerateResponse)
async def generate_korean_name(
    request: KoreanNameGenerateRequest,
    current_user: Optional[User] = Depends(get_optional_user)
):
    """
    한국 이름 생성 (인증 선택적)
    
    온보딩 단계에서 인증 없이도 사용 가능하도록 구현.
    인증된 사용자의 경우 current_user가 설정되고, 
    인증되지 않은 경우 None으로 처리됩니다.
    """
    try:
        service = KoreanNameService()
        korean_name, english_pronunciation = service.generate_korean_name(request.input_name)
        
        return KoreanNameGenerateResponse(
            success=True,
            message="한국 이름이 성공적으로 생성되었습니다",
            korean_name=korean_name,
            english_pronunciation=english_pronunciation
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"한국 이름 생성 실패: {str(e)}"
        )
