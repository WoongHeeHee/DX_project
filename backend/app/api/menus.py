"""
메뉴 관련 API 엔드포인트
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import MenuItem, SavedMenu
from app.models.schemas import (
    MenuItem as MenuItemSchema,
    SavedMenuCreate,
    SavedMenu as SavedMenuSchema,
    BaseResponse
)
from app.api.auth import get_current_user
from app.db.models import User

router = APIRouter()


@router.post("/{menu_item_id}/save", response_model=BaseResponse)
async def save_menu(
    menu_item_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """메뉴 찜하기 (저장)"""
    try:
        # 메뉴 존재 확인
        menu_item = db.query(MenuItem).filter(MenuItem.id == menu_item_id).first()
        if not menu_item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="메뉴를 찾을 수 없습니다"
            )
        
        # 이미 찜했는지 확인
        existing_saved = db.query(SavedMenu).filter(
            SavedMenu.user_id == current_user.id,
            SavedMenu.menu_item_id == menu_item_id
        ).first()
        
        if existing_saved:
            return BaseResponse(
                success=True,
                message="이미 찜한 메뉴입니다"
            )
        
        # 찜한 메뉴 생성
        saved_menu = SavedMenu(
            user_id=current_user.id,
            menu_item_id=menu_item_id
        )
        
        db.add(saved_menu)
        db.commit()
        
        return BaseResponse(
            success=True,
            message="메뉴가 저장되었습니다"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"메뉴 저장 실패: {str(e)}"
        )


@router.delete("/{menu_item_id}/save", response_model=BaseResponse)
async def unsave_menu(
    menu_item_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """찜한 메뉴 해제"""
    saved_menu = db.query(SavedMenu).filter(
        SavedMenu.user_id == current_user.id,
        SavedMenu.menu_item_id == menu_item_id
    ).first()
    
    if not saved_menu:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="찜한 메뉴를 찾을 수 없습니다"
        )
    
    try:
        db.delete(saved_menu)
        db.commit()
        
        return BaseResponse(
            success=True,
            message="저장이 해제되었습니다"
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"저장 해제 실패: {str(e)}"
        )


@router.get("/saved", response_model=List[MenuItemSchema])
async def get_saved_menus(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 20,
    offset: int = 0
):
    """내가 찜한 메뉴 목록 조회"""
    menu_items = db.query(MenuItem).join(SavedMenu).filter(
        SavedMenu.user_id == current_user.id
    ).order_by(SavedMenu.created_at.desc()).offset(offset).limit(limit).all()
    
    return menu_items

