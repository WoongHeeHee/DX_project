"""
SQLAlchemy 데이터베이스 모델
"""

import uuid
from enum import Enum as PyEnum
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, Text, ForeignKey, Enum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base


class AdventureLevel(PyEnum):
    """모험 수준"""
    CONSERVATIVE = "conservative"
    MODERATE = "moderate"
    ADVENTUROUS = "adventurous"


class KoreanExperience(PyEnum):
    """한국 경험 수준"""
    FIRST_TIME = "first_time"
    SOME_EXPERIENCE = "some_experience"
    FREQUENT_VISITOR = "frequent_visitor"
    LIVING_IN_KOREA = "living_in_korea"


class ActionType(PyEnum):
    """사용자 행동 타입"""
    PHOTO_UPLOAD = "photo_upload"
    LIKE = "like"
    PIN = "pin"
    DIARY_CREATE = "diary_create"
    SHOP_VISIT = "shop_visit"


class TargetType(PyEnum):
    """타겟 타입"""
    MENU_ITEM = "menu_item"
    SHOP = "shop"
    PHOTO = "photo"
    DIARY = "diary"


class User(Base):
    """사용자 테이블"""
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    google_id = Column(String(255), unique=True, nullable=True)
    display_name = Column(String(100), nullable=False)
    korean_name = Column(String(50), nullable=True)
    email = Column(String(255), nullable=True)
    country = Column(String(2), nullable=True)  # ISO 국가 코드
    birth_yyyy_mm = Column(String(7), nullable=True)  # YYYY-MM 형식
    spice_level = Column(Integer, default=3)  # 1-5 매운맛 수준
    adventure = Column(Enum(AdventureLevel), default=AdventureLevel.MODERATE)
    korean_experience = Column(Enum(KoreanExperience), default=KoreanExperience.FIRST_TIME)
    locale = Column(String(5), default="ko")  # ko, en, zh, ja
    onboarding_completed = Column(Boolean, default=False)  # 온보딩 완료 여부
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 관계
    photos = relationship("Photo", back_populates="uploader")
    likes = relationship("Like", back_populates="user")
    shop_pins = relationship("ShopPin", back_populates="user")
    saved_menus = relationship("SavedMenu", back_populates="user")
    diaries = relationship("Diary", back_populates="user")
    events = relationship("Event", back_populates="user")


class Market(Base):
    """시장 테이블"""
    __tablename__ = "markets"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=True)
    name_zh = Column(String(100), nullable=True)
    name_ja = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)  # 한국어 설명
    description_en = Column(Text, nullable=True)  # 영어 설명
    description_zh = Column(Text, nullable=True)  # 중국어 설명
    description_ja = Column(Text, nullable=True)  # 일본어 설명
    silhouette_url = Column(String(500), nullable=True)
    lat = Column(Float, nullable=True)  # 시장 중심 위도
    lng = Column(Float, nullable=True)  # 시장 중심 경도
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    shops = relationship("Shop", back_populates="market")
    market_menu_items = relationship("MarketMenuItem", back_populates="market")
    diaries = relationship("Diary", back_populates="market")
    market_info = relationship("MarketInfo", back_populates="market", uselist=False)


class MarketInfo(Base):
    """시장 부가정보 테이블"""
    __tablename__ = "market_info"
    
    market_info_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    market_id = Column(UUID(as_uuid=True), ForeignKey("markets.id"), nullable=False, unique=True)
    address = Column(String(500), nullable=True)  # 주소(한국어)
    address_en = Column(String(500), nullable=True)  # 주소(영어)
    address_zh = Column(String(500), nullable=True)  # 주소(중국어)
    address_ja = Column(String(500), nullable=True)  # 주소(일본어)
    transport = Column(Text, nullable=True)  # 대중교통 정보(한국어)
    transport_en = Column(Text, nullable=True)  # 대중교통 정보(영어)
    transport_zh = Column(Text, nullable=True)  # 대중교통 정보(중국어)
    transport_ja = Column(Text, nullable=True)  # 대중교통 정보(일본어)
    parking = Column(Text, nullable=True)  # 주차 정보(한국어)
    parking_en = Column(Text, nullable=True)  # 주차 정보(영어)
    parking_zh = Column(Text, nullable=True)  # 주차 정보(중국어)
    parking_ja = Column(Text, nullable=True)  # 주차 정보(일본어)
    restroom = Column(Text, nullable=True)  # 화장실 정보(한국어)
    restroom_en = Column(Text, nullable=True)  # 화장실 정보(영어)
    restroom_zh = Column(Text, nullable=True)  # 화장실 정보(중국어)
    restroom_ja = Column(Text, nullable=True)  # 화장실 정보(일본어)
    open_time = Column(String(5), nullable=True)  # 운영 시작 시간 (HH:MM 형식)
    close_time = Column(String(5), nullable=True)  # 운영 종료 시간 (HH:MM 형식)
    closed_days = Column(String(200), nullable=True)  # 휴무일 (한국어)
    closed_days_en = Column(String(200), nullable=True)  # 휴무일 (영어)
    closed_days_zh = Column(String(200), nullable=True)  # 휴무일 (중국어)
    closed_days_ja = Column(String(200), nullable=True)  # 휴무일 (일본어)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    market = relationship("Market", back_populates="market_info")


class Shop(Base):
    """가게 테이블"""
    __tablename__ = "shops"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    market_id = Column(UUID(as_uuid=True), ForeignKey("markets.id"), nullable=False)
    name = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=True)
    name_zh = Column(String(100), nullable=True)
    name_ja = Column(String(100), nullable=True)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    rep_image_url = Column(String(500), nullable=True)  # 가게 대표 사진
    open_time = Column(String(5), nullable=True)  # 운영 시작 시간 (HH:MM 형식)
    close_time = Column(String(5), nullable=True)  # 운영 종료 시간 (HH:MM 형식)
    closed_days = Column(String(200), nullable=True)  # 휴무일 (한국어)
    closed_days_en = Column(String(200), nullable=True)  # 휴무일 (영어)
    closed_days_zh = Column(String(200), nullable=True)  # 휴무일 (중국어)
    closed_days_ja = Column(String(200), nullable=True)  # 휴무일 (일본어)
    last_reported_open_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    market = relationship("Market", back_populates="shops")
    shop_menus = relationship("ShopMenu", back_populates="shop")
    shop_pins = relationship("ShopPin", back_populates="shop")
    photos = relationship("Photo", back_populates="shop")


class MenuItem(Base):
    """메뉴 아이템 테이블 (시장과 독립적)"""
    __tablename__ = "menu_items"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=True)
    name_zh = Column(String(100), nullable=True)
    name_ja = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)  # 메뉴 설명(한국어)
    description_en = Column(Text, nullable=True)  # 메뉴 설명(영어)
    description_zh = Column(Text, nullable=True)  # 메뉴 설명(중국어)
    description_ja = Column(Text, nullable=True)  # 메뉴 설명(일본어)
    similar_food = Column(String(200), nullable=True)  # 비슷한 메뉴(한국어)
    similar_food_en = Column(String(200), nullable=True)  # 비슷한 메뉴(영어)
    similar_food_zh = Column(String(200), nullable=True)  # 비슷한 메뉴(중국어)
    similar_food_ja = Column(String(200), nullable=True)  # 비슷한 메뉴(일본어)
    rep_image_url = Column(String(500), nullable=True)
    price = Column(String(100), nullable=True)  # 가격 범위 (예: "₩3,000~₩4,000")
    contains = Column(String(200), nullable=True)  # 알레르기(한국어)
    contains_en = Column(String(200), nullable=True)  # 알레르기(영어)
    contains_zh = Column(String(200), nullable=True)  # 알레르기(중국어)
    contains_ja = Column(String(200), nullable=True)  # 알레르기(일본어)
    may_contains = Column(String(200), nullable=True)  # 들어있을 수도 있는 알레르기(한국어)
    may_contains_en = Column(String(200), nullable=True)  # 들어있을 수도 있는 알레르기(영어)
    may_contains_zh = Column(String(200), nullable=True)  # 들어있을 수도 있는 알레르기(중국어)
    may_contains_ja = Column(String(200), nullable=True)  # 들어있을 수도 있는 알레르기(일본어)
    category = Column(String(50), nullable=True)  # 카테고리 (Meals, Snacks, Sweets, Drink 등)
    spice_level = Column(Integer, default=1)  # 1-5 매운맛 수준
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    market_menu_items = relationship("MarketMenuItem", back_populates="menu_item")
    shop_menus = relationship("ShopMenu", back_populates="menu_item")
    likes = relationship("Like", back_populates="menu_item")
    saved_menus = relationship("SavedMenu", back_populates="menu_item")
    photos = relationship("Photo", back_populates="menu_item", foreign_keys="[Photo.menu_item_id]")


class MarketMenuItem(Base):
    """시장-메뉴 조인 테이블 (다대다 관계)"""
    __tablename__ = "market_menu_items"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    market_id = Column(UUID(as_uuid=True), ForeignKey("markets.id"), nullable=False)
    menu_item_id = Column(UUID(as_uuid=True), ForeignKey("menu_items.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    market = relationship("Market", back_populates="market_menu_items")
    menu_item = relationship("MenuItem", back_populates="market_menu_items")


class ShopMenu(Base):
    """가게별 메뉴 테이블"""
    __tablename__ = "shop_menu"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    shop_id = Column(UUID(as_uuid=True), ForeignKey("shops.id"), nullable=False)
    menu_item_id = Column(UUID(as_uuid=True), ForeignKey("menu_items.id"), nullable=False)
    available = Column(Boolean, default=True)
    photo_id = Column(UUID(as_uuid=True), ForeignKey("photos.id"), nullable=True)  # 가게별 메뉴 사진
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    shop = relationship("Shop", back_populates="shop_menus")
    menu_item = relationship("MenuItem", back_populates="shop_menus")
    photo = relationship("Photo", foreign_keys=[photo_id])


class Photo(Base):
    """사진 테이블 (음식 사진만 저장)"""
    __tablename__ = "photos"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    uploader_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    shop_id = Column(UUID(as_uuid=True), ForeignKey("shops.id"), nullable=True)  # 제보/리뷰용 사진의 가게 ID
    menu_item_id = Column(UUID(as_uuid=True), ForeignKey("menu_items.id"), nullable=True)  # 음식 메뉴 ID (FK) - 처리 후 설정
    upload_token = Column(String(255), nullable=True)  # 비회원용 임시 토큰
    s3_key = Column(String(500), nullable=False)
    thumbnail_s3_key = Column(String(500), nullable=True)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    taken_at = Column(DateTime(timezone=True), nullable=False)
    processed = Column(Boolean, default=False)
    menu_item_id = Column(UUID(as_uuid=True), ForeignKey("menu_items.id"), nullable=True)  # 음식 메뉴 ID (FK) - 처리 후 설정
    photo_type = Column(String(20), nullable=True)  # 'report' (제보용) or 'review' (리뷰용)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    uploader = relationship("User", back_populates="photos", foreign_keys=[uploader_user_id])
    shop = relationship("Shop", back_populates="photos")
    menu_item = relationship("MenuItem", foreign_keys=[menu_item_id])
    shop_menu_photos = relationship("ShopMenu", foreign_keys="[ShopMenu.photo_id]")


class Like(Base):
    """좋아요 테이블"""
    __tablename__ = "likes"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    menu_item_id = Column(UUID(as_uuid=True), ForeignKey("menu_items.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    user = relationship("User", back_populates="likes")
    menu_item = relationship("MenuItem", back_populates="likes")


class ShopPin(Base):
    """핀한 가게 테이블"""
    __tablename__ = "shop_pins"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    shop_id = Column(UUID(as_uuid=True), ForeignKey("shops.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    user = relationship("User", back_populates="shop_pins")
    shop = relationship("Shop", back_populates="shop_pins")


class SavedMenu(Base):
    """찜한 메뉴 테이블 (저장한 메뉴)"""
    __tablename__ = "saved_menus"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    menu_item_id = Column(UUID(as_uuid=True), ForeignKey("menu_items.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    user = relationship("User", back_populates="saved_menus")
    menu_item = relationship("MenuItem", back_populates="saved_menus")


class Diary(Base):
    """다이어리 테이블"""
    __tablename__ = "diaries"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    market_id = Column(UUID(as_uuid=True), ForeignKey("markets.id"), nullable=False)
    content = Column(Text, nullable=True)
    photo_ids = Column(JSONB, nullable=True)  # 사진 ID 배열
    keywords = Column(JSONB, nullable=True)  # 키워드 배열
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    user = relationship("User", back_populates="diaries")
    market = relationship("Market", back_populates="diaries")


class KeywordReview(Base):
    """키워드 리뷰 집계 테이블"""
    __tablename__ = "keyword_reviews"
    
    market_id = Column(UUID(as_uuid=True), ForeignKey("markets.id"), primary_key=True)
    keyword = Column(String(50), primary_key=True)
    count = Column(Integer, default=0)
    last_updated = Column(DateTime(timezone=True), server_default=func.now())


class Event(Base):
    """사용자 이벤트 테이블 (추천 시스템용)"""
    __tablename__ = "events"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    action_type = Column(Enum(ActionType), nullable=False)
    target_type = Column(Enum(TargetType), nullable=False)
    target_id = Column(UUID(as_uuid=True), nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    user = relationship("User", back_populates="events")
