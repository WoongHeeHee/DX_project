"""
Pydantic 스키마 모델
"""

from datetime import datetime
from typing import List, Optional, Dict, Any
from uuid import UUID
from pydantic import BaseModel, Field
from enum import Enum


class AdventureLevel(str, Enum):
    """모험 수준"""
    CONSERVATIVE = "conservative"
    MODERATE = "moderate"
    ADVENTUROUS = "adventurous"


class KoreanExperience(str, Enum):
    """한국 경험 수준"""
    FIRST_TIME = "first_time"
    SOME_EXPERIENCE = "some_experience"
    FREQUENT_VISITOR = "frequent_visitor"
    LIVING_IN_KOREA = "living_in_korea"


class ActionType(str, Enum):
    """사용자 행동 타입"""
    PHOTO_UPLOAD = "photo_upload"
    LIKE = "like"
    PIN = "pin"
    DIARY_CREATE = "diary_create"
    SHOP_VISIT = "shop_visit"


# 기본 응답 모델
class BaseResponse(BaseModel):
    """기본 응답 모델"""
    success: bool = True
    message: str = ""


class ErrorResponse(BaseResponse):
    """오류 응답 모델"""
    success: bool = False
    error_code: str
    details: Optional[Dict[str, Any]] = None


# 사용자 관련 모델
class UserBase(BaseModel):
    """사용자 기본 모델"""
    display_name: str = Field(..., min_length=1, max_length=100)
    korean_name: Optional[str] = Field(None, max_length=50)
    country: Optional[str] = Field(None, max_length=2)
    birth_yyyy_mm: Optional[str] = Field(None, pattern=r'^\d{4}-\d{2}$')
    spice_level: int = Field(3, ge=1, le=5)
    adventure: AdventureLevel = AdventureLevel.MODERATE
    korean_experience: KoreanExperience = KoreanExperience.FIRST_TIME
    locale: str = Field("ko", pattern=r'^(ko|en|zh|ja)$')


class UserCreate(UserBase):
    """사용자 생성 모델"""
    google_id: Optional[str] = None
    email: Optional[str] = None


class UserUpdate(BaseModel):
    """사용자 업데이트 모델"""
    display_name: Optional[str] = Field(None, min_length=1, max_length=100)
    korean_name: Optional[str] = Field(None, max_length=50)
    country: Optional[str] = Field(None, max_length=2)
    birth_yyyy_mm: Optional[str] = Field(None, pattern=r'^\d{4}-\d{2}$')
    spice_level: Optional[int] = Field(None, ge=1, le=5)
    adventure: Optional[AdventureLevel] = None
    korean_experience: Optional[KoreanExperience] = None
    locale: Optional[str] = Field(None, pattern=r'^(ko|en|zh|ja)$')


class User(UserBase):
    """사용자 응답 모델"""
    id: UUID
    email: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# 인증 관련 모델
class Token(BaseModel):
    """토큰 모델"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class GoogleAuthRequest(BaseModel):
    """Google 인증 요청"""
    code: str
    redirect_uri: str


# 시장 관련 모델
class MarketBase(BaseModel):
    """시장 기본 모델"""
    name: str = Field(..., min_length=1, max_length=100)
    name_en: Optional[str] = Field(None, max_length=100)
    name_zh: Optional[str] = Field(None, max_length=100)
    name_ja: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    silhouette_url: Optional[str] = None


class Market(MarketBase):
    """시장 응답 모델"""
    id: UUID
    created_at: datetime

    class Config:
        from_attributes = True


# 가게 관련 모델
class ShopBase(BaseModel):
    """가게 기본 모델"""
    name: str = Field(..., min_length=1, max_length=100)
    name_en: Optional[str] = Field(None, max_length=100)
    name_zh: Optional[str] = Field(None, max_length=100)
    name_ja: Optional[str] = Field(None, max_length=100)
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    address: Optional[str] = Field(None, max_length=200)


class Shop(ShopBase):
    """가게 응답 모델"""
    id: UUID
    market_id: UUID
    last_reported_open_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


class ShopWithDistance(Shop):
    """거리 정보가 포함된 가게 모델"""
    distance_meters: float


# 메뉴 관련 모델
class MenuItemBase(BaseModel):
    """메뉴 아이템 기본 모델"""
    name: str = Field(..., min_length=1, max_length=100)
    name_en: Optional[str] = Field(None, max_length=100)
    name_zh: Optional[str] = Field(None, max_length=100)
    name_ja: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    rep_image_url: Optional[str] = None
    tags: Optional[Dict[str, Any]] = None
    spice_level: int = Field(1, ge=1, le=5)


class MenuItem(MenuItemBase):
    """메뉴 아이템 응답 모델"""
    id: UUID
    market_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True


# 사진 관련 모델
class PhotoUploadInit(BaseModel):
    """사진 업로드 초기화 요청"""
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    taken_at: datetime
    is_member: bool = False


class PhotoUploadInitResponse(BaseResponse):
    """사진 업로드 초기화 응답"""
    presigned_url: str
    upload_token: str
    s3_key: str


class PhotoUploadComplete(BaseModel):
    """사진 업로드 완료 요청"""
    upload_token: str
    s3_key: str
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    taken_at: datetime
    uploader_user_id: Optional[UUID] = None


class Photo(BaseModel):
    """사진 응답 모델"""
    id: UUID
    s3_key: str
    thumbnail_s3_key: Optional[str] = None
    lat: float
    lng: float
    taken_at: datetime
    processed: bool
    parsed_items: Optional[Dict[str, Any]] = None
    created_at: datetime

    class Config:
        from_attributes = True


# 검색 관련 모델
class ImageSearchRequest(BaseModel):
    """이미지 검색 요청"""
    image_url: str
    user_prompt: Optional[str] = None
    lat: Optional[float] = Field(None, ge=-90, le=90)
    lng: Optional[float] = Field(None, ge=-180, le=180)


class SearchResult(BaseModel):
    """검색 결과"""
    menu_item: MenuItem
    confidence: float
    shops_nearby: List[ShopWithDistance] = []


class ImageSearchResponse(BaseResponse):
    """이미지 검색 응답"""
    results: List[SearchResult]


# 좋아요/핀 관련 모델
class LikeCreate(BaseModel):
    """좋아요 생성 요청"""
    menu_item_id: UUID


class PinCreate(BaseModel):
    """핀 생성 요청"""
    shop_id: Optional[UUID] = None
    menu_item_id: Optional[UUID] = None


# 다이어리 관련 모델
class DiaryCreate(BaseModel):
    """다이어리 생성 요청"""
    market_id: UUID
    content: Optional[str] = None
    photo_ids: Optional[List[UUID]] = None
    keywords: Optional[List[str]] = None


class Diary(BaseModel):
    """다이어리 응답 모델"""
    id: UUID
    user_id: UUID
    market_id: UUID
    content: Optional[str] = None
    photo_ids: Optional[List[UUID]] = None
    keywords: Optional[List[str]] = None
    created_at: datetime

    class Config:
        from_attributes = True


# 추천 관련 모델
class RecommendationRequest(BaseModel):
    """추천 요청"""
    user_id: Optional[UUID] = None
    limit: int = Field(10, ge=1, le=50)
    category: Optional[str] = None


class RecommendationResponse(BaseResponse):
    """추천 응답"""
    recommendations: List[MenuItem]
    recommendation_type: str  # "collaborative", "popularity", "cold_start"


# 통계 관련 모델
class MarketStats(BaseModel):
    """시장 통계"""
    total_shops: int
    total_menu_items: int
    recent_photos_count: int
    popular_keywords: List[Dict[str, Any]]


# 근처 가게 검색 요청
class NearbyShopsRequest(BaseModel):
    """근처 가게 검색 요청"""
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    radius_meters: int = Field(5, ge=1, le=1000)
    market_id: Optional[UUID] = None


class NearbyShopsResponse(BaseResponse):
    """근처 가게 검색 응답"""
    shops: List[ShopWithDistance]
    total_count: int
