"""
메뉴 관련 API 엔드포인트
"""

from typing import List, Optional
from datetime import datetime
from urllib.parse import quote
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
from app.api.auth import get_current_user, get_optional_user
from app.db.models import User

router = APIRouter()


@router.get("/", response_model=List[MenuItemSchema])
async def list_menus(
    category: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    """메뉴 리스트 조회 (카테고리별 필터 가능)"""
    query = db.query(MenuItem)
    if category:
        query = query.filter(MenuItem.category == category)
    rows = (
        query.order_by(MenuItem.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    def to_schema(m: MenuItem) -> MenuItemSchema:
        created_at = m.created_at or datetime.utcnow()
        name = m.name or "메뉴"
        rep_image_url = m.rep_image_url
        if not rep_image_url:
            enc = quote(name)
            rep_image_url = (
                f"https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/"
                f"{enc}/{enc}1_{m.id}.png"
            )
        return MenuItemSchema.model_validate(
            {
                "id": m.id,
                "name": name,
                "name_en": getattr(m, "name_en", None),
                "name_zh": getattr(m, "name_zh", None),
                "name_ja": getattr(m, "name_ja", None),
                "description": getattr(m, "description", None),
                "description_en": getattr(m, "description_en", None),
                "description_zh": getattr(m, "description_zh", None),
                "description_ja": getattr(m, "description_ja", None),
                "similar_food": getattr(m, "similar_food", None),
                "similar_food_en": getattr(m, "similar_food_en", None),
                "similar_food_zh": getattr(m, "similar_food_zh", None),
                "similar_food_ja": getattr(m, "similar_food_ja", None),
                "rep_image_url": rep_image_url,
                "price": getattr(m, "price", None),
                "contains": getattr(m, "contains", None),
                "contains_en": getattr(m, "contains_en", None),
                "contains_zh": getattr(m, "contains_zh", None),
                "contains_ja": getattr(m, "contains_ja", None),
                "may_contains": getattr(m, "may_contains", None),
                "may_contains_en": getattr(m, "may_contains_en", None),
                "may_contains_zh": getattr(m, "may_contains_zh", None),
                "may_contains_ja": getattr(m, "may_contains_ja", None),
                "category": getattr(m, "category", None),
                "spice_level": getattr(m, "spice_level", 1) or 1,
                "created_at": created_at,
            }
        )

    return [to_schema(m) for m in rows]


@router.get("/{menu_item_id}", response_model=MenuItemSchema)
async def get_menu_item(
    menu_item_id: str,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db)
):
    """특정 메뉴 아이템 상세 조회 (저장 여부 포함)"""
    menu_item = db.query(MenuItem).filter(MenuItem.id == menu_item_id).first()
    
    if not menu_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="메뉴를 찾을 수 없습니다"
        )
    
    # 저장 여부 확인 (인증된 사용자인 경우만)
    is_saved = False
    if current_user:
        saved_menu = db.query(SavedMenu).filter(
            SavedMenu.user_id == current_user.id,
            SavedMenu.menu_item_id == menu_item_id
        ).first()
        is_saved = saved_menu is not None
    
    # 스키마 변환
    created_at = menu_item.created_at or datetime.utcnow()
    name = menu_item.name or "메뉴"
    rep_image_url = menu_item.rep_image_url
    if not rep_image_url:
        enc = quote(name)
        rep_image_url = (
            f"https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/"
            f"{enc}/{enc}1_{menu_item.id}.png"
        )
    
    return MenuItemSchema.model_validate(
        {
            "id": menu_item.id,
            "name": name,
            "name_en": getattr(menu_item, "name_en", None),
            "name_zh": getattr(menu_item, "name_zh", None),
            "name_ja": getattr(menu_item, "name_ja", None),
            "description": getattr(menu_item, "description", None),
            "description_en": getattr(menu_item, "description_en", None),
            "description_zh": getattr(menu_item, "description_zh", None),
            "description_ja": getattr(menu_item, "description_ja", None),
            "similar_food": getattr(menu_item, "similar_food", None),
            "similar_food_en": getattr(menu_item, "similar_food_en", None),
            "similar_food_zh": getattr(menu_item, "similar_food_zh", None),
            "similar_food_ja": getattr(menu_item, "similar_food_ja", None),
            "rep_image_url": rep_image_url,
            "price": getattr(menu_item, "price", None),
            "contains": getattr(menu_item, "contains", None),
            "contains_en": getattr(menu_item, "contains_en", None),
            "contains_zh": getattr(menu_item, "contains_zh", None),
            "contains_ja": getattr(menu_item, "contains_ja", None),
            "may_contains": getattr(menu_item, "may_contains", None),
            "may_contains_en": getattr(menu_item, "may_contains_en", None),
            "may_contains_zh": getattr(menu_item, "may_contains_zh", None),
            "may_contains_ja": getattr(menu_item, "may_contains_ja", None),
            "category": getattr(menu_item, "category", None),
            "spice_level": getattr(menu_item, "spice_level", 1) or 1,
            "created_at": created_at,
            "is_saved": is_saved,
        }
    )


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

