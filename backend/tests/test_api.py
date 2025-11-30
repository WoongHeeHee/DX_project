"""
API 엔드포인트 테스트
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.db.database import get_db, Base
from app.db.models import User, Market, MenuItem, Shop

# 테스트용 데이터베이스 설정
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(scope="module")
def client():
    """테스트 클라이언트 생성"""
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as c:
        yield c
    Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="module")
def test_data():
    """테스트 데이터 생성"""
    db = TestingSessionLocal()
    
    # 테스트 시장 생성
    market = Market(
        name="테스트 시장",
        name_en="Test Market",
        description="테스트용 시장입니다"
    )
    db.add(market)
    db.flush()
    
    # 테스트 메뉴 아이템 생성
    menu_item = MenuItem(
        market_id=market.id,
        name="테스트 메뉴",
        name_en="Test Menu",
        description="테스트용 메뉴입니다",
        spice_level=2
    )
    db.add(menu_item)
    db.flush()
    
    # 테스트 가게 생성
    shop = Shop(
        market_id=market.id,
        name="테스트 가게",
        name_en="Test Shop",
        lat=37.5703,
        lng=126.9998,
        geom="POINT(126.9998 37.5703)"
    )
    db.add(shop)
    
    db.commit()
    
    data = {
        "market_id": str(market.id),
        "menu_item_id": str(menu_item.id),
        "shop_id": str(shop.id)
    }
    
    db.close()
    return data

class TestHealthCheck:
    """헬스체크 테스트"""
    
    def test_health_check(self, client):
        """헬스체크 엔드포인트 테스트"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "service" in data
        assert "version" in data

class TestMarkets:
    """시장 관련 API 테스트"""
    
    def test_get_markets(self, client, test_data):
        """시장 목록 조회 테스트"""
        response = client.get("/markets/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0
        
        market = data[0]
        assert "id" in market
        assert "name" in market
        assert market["name"] == "테스트 시장"
    
    def test_get_market_detail(self, client, test_data):
        """시장 상세 정보 조회 테스트"""
        market_id = test_data["market_id"]
        response = client.get(f"/markets/{market_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == market_id
        assert data["name"] == "테스트 시장"
    
    def test_get_market_menu_items(self, client, test_data):
        """시장 메뉴 아이템 조회 테스트"""
        market_id = test_data["market_id"]
        response = client.get(f"/markets/{market_id}/menu-items")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0
        
        menu_item = data[0]
        assert "id" in menu_item
        assert "name" in menu_item
        assert menu_item["name"] == "테스트 메뉴"

class TestShops:
    """가게 관련 API 테스트"""
    
    def test_nearby_shops(self, client, test_data):
        """근처 가게 검색 테스트"""
        request_data = {
            "lat": 37.5703,
            "lng": 126.9998,
            "radius_meters": 1000
        }
        
        response = client.post("/shops/nearby", json=request_data)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "shops" in data
        assert "total_count" in data
    
    def test_get_shop_detail(self, client, test_data):
        """가게 상세 정보 조회 테스트"""
        shop_id = test_data["shop_id"]
        response = client.get(f"/shops/{shop_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == shop_id
        assert data["name"] == "테스트 가게"

class TestPhotos:
    """사진 업로드 관련 API 테스트"""
    
    def test_photo_upload_init(self, client):
        """사진 업로드 초기화 테스트"""
        request_data = {
            "lat": 37.5703,
            "lng": 126.9998,
            "taken_at": "2024-01-01T12:00:00Z",
            "is_member": False
        }
        
        response = client.post("/uploads/photo-init", json=request_data)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "presigned_url" in data
        assert "upload_token" in data
        assert "s3_key" in data

class TestSearch:
    """검색 관련 API 테스트"""
    
    def test_menu_items_search(self, client, test_data):
        """메뉴 아이템 텍스트 검색 테스트"""
        response = client.get("/search/menu-items?q=테스트")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
    
    def test_popular_menus(self, client, test_data):
        """인기 메뉴 조회 테스트"""
        response = client.get("/search/popular-menus")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

class TestAuth:
    """인증 관련 API 테스트"""
    
    def test_auth_endpoints_exist(self, client):
        """인증 엔드포인트 존재 확인"""
        # Google 인증 엔드포인트 (실제 토큰 없이는 400 에러 예상)
        response = client.post("/auth/google", json={"code": "invalid", "redirect_uri": "test"})
        assert response.status_code == 400  # 유효하지 않은 토큰이므로 400 예상
        
        # 현재 사용자 정보 (인증 없이는 401 에러 예상)
        response = client.get("/auth/me")
        assert response.status_code == 401  # 인증되지 않았으므로 401 예상

if __name__ == "__main__":
    pytest.main([__file__])
