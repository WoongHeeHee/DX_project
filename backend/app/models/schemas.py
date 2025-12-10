"""
Pydantic 스키마 모델
"""

from datetime import datetime
from typing import List, Optional, Dict, Any
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
    spice_level: Optional[int] = Field(None, ge=1, le=5)
    adventure: Optional[AdventureLevel] = None
    korean_experience: Optional[KoreanExperience] = None
    locale: str = Field("ko", pattern=r'^(ko|en|zh|ja)$')


class UserCreate(UserBase):
    """사용자 생성 모델"""
    google_id: Optional[str] = None
    email: Optional[str] = None


class UserUpdate(BaseModel):
    """사용자 업데이트 모델"""
    display_name: Optional[str] = Field(None, min_length=1, max_length=100)
    korean_name: Optional[str] = Field(None, max_length=100)  # (한글이름, 영어발음) 형식으로 저장
    country: Optional[str] = Field(None, max_length=2)
    birth_yyyy_mm: Optional[str] = Field(None, pattern=r'^\d{4}-\d{2}$')
    spice_level: Optional[int] = Field(None, ge=1, le=5)
    adventure: Optional[AdventureLevel] = None
    korean_experience: Optional[KoreanExperience] = None
    locale: Optional[str] = Field(None, pattern=r'^(ko|en|zh|ja)$')


class User(UserBase):
    """사용자 응답 모델"""
    id: str
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
    id_token: str = Field(..., description="Google ID Token")
    redirect_uri: Optional[str] = Field(None, description="리디렉션 URI (선택사항)")


# 한국 이름 생성 관련 모델
class KoreanNameGenerateRequest(BaseModel):
    """한국 이름 생성 요청"""
    input_name: str = Field(..., min_length=1, max_length=100, description="원본 이름 (영어, 중국어, 일본어 등)")


class KoreanNameGenerateResponse(BaseResponse):
    """한국 이름 생성 응답"""
    korean_name: str
    english_pronunciation: str


# 시장 관련 모델
class MarketBase(BaseModel):
    """시장 기본 모델"""
    name: str = Field(..., min_length=1, max_length=100)
    name_en: Optional[str] = Field(None, max_length=100)
    name_zh: Optional[str] = Field(None, max_length=100)
    name_ja: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None  # 한국어 설명
    description_en: Optional[str] = None  # 영어 설명
    description_zh: Optional[str] = None  # 중국어 설명
    description_ja: Optional[str] = None  # 일본어 설명
    silhouette_url: Optional[str] = None
    lat: Optional[float] = Field(None, ge=-90, le=90, description="시장 중심 위도")
    lng: Optional[float] = Field(None, ge=-180, le=180, description="시장 중심 경도")


class Market(MarketBase):
    """시장 응답 모델"""
    id: str
    created_at: datetime

    class Config:
        from_attributes = True


# 시장 부가정보 관련 모델
class MarketInfoBase(BaseModel):
    """시장 부가정보 기본 모델"""
    address: Optional[str] = None
    address_en: Optional[str] = None
    address_zh: Optional[str] = None
    address_ja: Optional[str] = None
    transport: Optional[str] = None
    transport_en: Optional[str] = None
    transport_zh: Optional[str] = None
    transport_ja: Optional[str] = None
    parking: Optional[str] = None
    parking_en: Optional[str] = None
    parking_zh: Optional[str] = None
    parking_ja: Optional[str] = None
    restroom: Optional[str] = None
    restroom_en: Optional[str] = None
    restroom_zh: Optional[str] = None
    restroom_ja: Optional[str] = None
    open_time: Optional[str] = None  # 운영 시작 시간 (HH:MM 형식)
    close_time: Optional[str] = None  # 운영 종료 시간 (HH:MM 형식)
    closed_days: Optional[str] = None  # 휴무일 (한국어)
    closed_days_en: Optional[str] = None  # 휴무일 (영어)
    closed_days_zh: Optional[str] = None  # 휴무일 (중국어)
    closed_days_ja: Optional[str] = None  # 휴무일 (일본어)


class MarketInfo(MarketInfoBase):
    """시장 부가정보 응답 모델"""
    market_info_id: str
    market_id: str
    created_at: datetime

    class Config:
        from_attributes = True


class MarketInfoCreate(MarketInfoBase):
    """시장 부가정보 생성 모델"""
    market_id: str


# 가게 관련 모델
class ShopBase(BaseModel):
    """가게 기본 모델"""
    name: str = Field(..., min_length=1, max_length=100)
    name_en: Optional[str] = Field(None, max_length=100)
    name_zh: Optional[str] = Field(None, max_length=100)
    name_ja: Optional[str] = Field(None, max_length=100)
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    closed_days: Optional[str] = Field(None, max_length=200)  # 휴무일 (한국어)
    closed_days_en: Optional[str] = Field(None, max_length=200)  # 휴무일 (영어)
    closed_days_zh: Optional[str] = Field(None, max_length=200)  # 휴무일 (중국어)
    closed_days_ja: Optional[str] = Field(None, max_length=200)  # 휴무일 (일본어)


class Shop(ShopBase):
    """가게 응답 모델"""
    id: str
    market_id: str
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
    description: Optional[str] = None  # 한국어 설명
    description_en: Optional[str] = None  # 영어 설명
    description_zh: Optional[str] = None  # 중국어 설명
    description_ja: Optional[str] = None  # 일본어 설명
    similar_food: Optional[str] = Field(None, max_length=200)  # 비슷한 메뉴(한국어)
    similar_food_en: Optional[str] = Field(None, max_length=200)  # 비슷한 메뉴(영어)
    similar_food_zh: Optional[str] = Field(None, max_length=200)  # 비슷한 메뉴(중국어)
    similar_food_ja: Optional[str] = Field(None, max_length=200)  # 비슷한 메뉴(일본어)
    rep_image_url: Optional[str] = None
    price: Optional[str] = Field(None, max_length=100, description="가격 범위 (예: ₩3,000~₩4,000)")
    contains: Optional[str] = Field(None, max_length=200)  # 알레르기(한국어)
    contains_en: Optional[str] = Field(None, max_length=200)  # 알레르기(영어)
    contains_zh: Optional[str] = Field(None, max_length=200)  # 알레르기(중국어)
    contains_ja: Optional[str] = Field(None, max_length=200)  # 알레르기(일본어)
    may_contains: Optional[str] = Field(None, max_length=200)  # 들어있을 수도 있는 알레르기(한국어)
    may_contains_en: Optional[str] = Field(None, max_length=200)  # 들어있을 수도 있는 알레르기(영어)
    may_contains_zh: Optional[str] = Field(None, max_length=200)  # 들어있을 수도 있는 알레르기(중국어)
    may_contains_ja: Optional[str] = Field(None, max_length=200)  # 들어있을 수도 있는 알레르기(일본어)
    category: Optional[str] = Field(None, max_length=50)
    spice_level: int = Field(1, ge=1, le=5)


class MenuItem(MenuItemBase):
    """메뉴 아이템 응답 모델"""
    id: str
    created_at: Optional[datetime] = None  # 기존 데이터 호환성을 위해 Optional로 변경
    is_saved: Optional[bool] = Field(None, description="현재 사용자가 저장했는지 여부 (인증된 사용자만)")

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
    uploader_user_id: Optional[str] = None
    photo_type: Optional[str] = Field(None, description="'report' (제보용) or 'review' (리뷰용)")


class PhotoReportComplete(BaseModel):
    """제보 완료 요청 (가게 선택 후)"""
    upload_token: str
    shop_id: str


class Photo(BaseModel):
    """사진 응답 모델 (음식 사진만 저장)"""
    id: str
    s3_key: str
    thumbnail_s3_key: Optional[str] = None
    lat: float
    lng: float
    taken_at: datetime
    processed: bool
    menu_item_id: Optional[str] = None  # 음식 메뉴 ID (FK) - 처리 후 설정
    created_at: datetime

    class Config:
        from_attributes = True


# 검색 관련 모델
class ImageSearchRequest(BaseModel):
    """이미지/텍스트 검색 요청"""
    image_url: Optional[str] = None
    user_text: Optional[str] = None  # 사용자 텍스트 설명 (user_prompt 대신 user_text 사용)
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


# 좋아요 관련 모델
class LikeCreate(BaseModel):
    """좋아요 생성 요청"""
    menu_item_id: str


# 핀한 가게 관련 모델
class ShopPinCreate(BaseModel):
    """핀한 가게 생성 요청"""
    shop_id: str


class ShopPin(BaseModel):
    """핀한 가게 응답 모델"""
    id: str
    user_id: str
    shop_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# 찜한 메뉴 관련 모델
class SavedMenuCreate(BaseModel):
    """찜한 메뉴 생성 요청"""
    menu_item_id: str


class SavedMenu(BaseModel):
    """찜한 메뉴 응답 모델"""
    id: str
    user_id: str
    menu_item_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# 다이어리 관련 모델
class DiaryCreate(BaseModel):
    """다이어리 생성 요청"""
    market_id: str
    content: Optional[str] = None
    photo_ids: Optional[List[str]] = None
    keywords: Optional[List[str]] = None


class Diary(BaseModel):
    """다이어리 응답 모델"""
    id: str
    user_id: str
    market_id: str
    content: Optional[str] = None
    photo_ids: Optional[List[str]] = None
    keywords: Optional[List[str]] = None
    created_at: datetime

    class Config:
        from_attributes = True


# 추천 관련 모델
class RecommendationRequest(BaseModel):
    """추천 요청"""
    user_id: Optional[str] = None
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
    market_id: Optional[str] = None


class NearbyShopsResponse(BaseResponse):
    """근처 가게 검색 응답"""
    shops: List[ShopWithDistance]
    total_count: int
