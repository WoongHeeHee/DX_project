"""
SQLAlchemy 데이터베이스 모델
"""

import uuid
from datetime import datetime
from enum import Enum as PyEnum
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, Text, JSON, ForeignKey, Enum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from geoalchemy2 import Geography
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
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 관계
    photos = relationship("Photo", back_populates="uploader")
    likes = relationship("Like", back_populates="user")
    pins = relationship("Pin", back_populates="user")
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
    description = Column(Text, nullable=True)
    silhouette_url = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    shops = relationship("Shop", back_populates="market")
    menu_items = relationship("MenuItem", back_populates="market")
    diaries = relationship("Diary", back_populates="market")


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
    geom = Column(Geography('POINT'), nullable=False)
    address = Column(String(200), nullable=True)
    last_reported_open_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    market = relationship("Market", back_populates="shops")
    shop_menus = relationship("ShopMenu", back_populates="shop")
    pins = relationship("Pin", back_populates="shop")


class MenuItem(Base):
    """메뉴 아이템 테이블"""
    __tablename__ = "menu_items"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    market_id = Column(UUID(as_uuid=True), ForeignKey("markets.id"), nullable=False)
    name = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=True)
    name_zh = Column(String(100), nullable=True)
    name_ja = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)
    rep_image_url = Column(String(500), nullable=True)
    tags = Column(JSONB, nullable=True)
    spice_level = Column(Integer, default=1)  # 1-5 매운맛 수준
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    market = relationship("Market", back_populates="menu_items")
    shop_menus = relationship("ShopMenu", back_populates="menu_item")
    likes = relationship("Like", back_populates="menu_item")
    pins = relationship("Pin", back_populates="menu_item")


class ShopMenu(Base):
    """가게별 메뉴 테이블"""
    __tablename__ = "shop_menu"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    shop_id = Column(UUID(as_uuid=True), ForeignKey("shops.id"), nullable=False)
    menu_item_id = Column(UUID(as_uuid=True), ForeignKey("menu_items.id"), nullable=False)
    price = Column(Integer, nullable=True)  # 원 단위
    available = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    shop = relationship("Shop", back_populates="shop_menus")
    menu_item = relationship("MenuItem", back_populates="shop_menus")


class Photo(Base):
    """사진 테이블"""
    __tablename__ = "photos"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    uploader_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    upload_token = Column(String(255), nullable=True)  # 비회원용 임시 토큰
    s3_key = Column(String(500), nullable=False)
    thumbnail_s3_key = Column(String(500), nullable=True)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    taken_at = Column(DateTime(timezone=True), nullable=False)
    processed = Column(Boolean, default=False)
    parsed_items = Column(JSONB, nullable=True)  # 파싱된 음식 정보
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    uploader = relationship("User", back_populates="photos")


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


class Pin(Base):
    """핀 테이블 (북마크)"""
    __tablename__ = "pins"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    shop_id = Column(UUID(as_uuid=True), ForeignKey("shops.id"), nullable=True)
    menu_item_id = Column(UUID(as_uuid=True), ForeignKey("menu_items.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 관계
    user = relationship("User", back_populates="pins")
    shop = relationship("Shop", back_populates="pins")
    menu_item = relationship("MenuItem", back_populates="pins")


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
