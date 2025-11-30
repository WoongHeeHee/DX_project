"""
시드 데이터 생성 스크립트
"""

import uuid
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from geoalchemy2 import func as geo_func

from app.db.database import SessionLocal, engine
from app.db.models import *

def create_seed_data():
    """시드 데이터 생성"""
    db = SessionLocal()
    
    try:
        print("🌱 시드 데이터 생성 시작...")
        
        # 1. 시장 생성
        print("📍 시장 데이터 생성 중...")
        market = Market(
            id=uuid.uuid4(),
            name="광장시장",
            name_en="Gwangjang Market",
            name_zh="广藏市场",
            name_ja="広蔵市場",
            description="서울의 대표적인 전통시장으로 다양한 한국 음식을 맛볼 수 있습니다.",
            silhouette_url="https://example.com/gwangjang_silhouette.jpg"
        )
        db.add(market)
        db.flush()  # ID 생성을 위해
        
        # 2. 메뉴 아이템 생성
        print("🍜 메뉴 아이템 생성 중...")
        menu_items_data = [
            {
                "name": "빈대떡", "name_en": "Mung Bean Pancake", "name_zh": "绿豆煎饼", "name_ja": "緑豆チヂミ",
                "description": "녹두를 갈아 만든 전통 한국 팬케이크", "spice_level": 1,
                "tags": {"categories": ["전통음식", "팬케이크", "채식"], "allergens": ["글루텐"]}
            },
            {
                "name": "김치전", "name_en": "Kimchi Pancake", "name_zh": "泡菜煎饼", "name_ja": "キムチチヂミ",
                "description": "발효된 김치로 만든 매콤한 팬케이크", "spice_level": 3,
                "tags": {"categories": ["김치", "팬케이크", "매운맛"], "allergens": ["글루텐"]}
            },
            {
                "name": "떡볶이", "name_en": "Tteokbokki", "name_zh": "年糕", "name_ja": "トッポッキ",
                "description": "매콤달콤한 고추장 소스의 떡 요리", "spice_level": 4,
                "tags": {"categories": ["떡", "매운맛", "길거리음식"], "allergens": []}
            },
            {
                "name": "순대", "name_en": "Korean Blood Sausage", "name_zh": "血肠", "name_ja": "スンデ",
                "description": "돼지 내장에 당면과 야채를 넣어 만든 순대", "spice_level": 1,
                "tags": {"categories": ["내장", "전통음식"], "allergens": []}
            },
            {
                "name": "김밥", "name_en": "Kimbap", "name_zh": "紫菜包饭", "name_ja": "キンパプ",
                "description": "김에 밥과 다양한 재료를 말아 만든 음식", "spice_level": 1,
                "tags": {"categories": ["밥", "김", "간편식"], "allergens": ["참깨"]}
            },
            {
                "name": "붕어빵", "name_en": "Fish-shaped Pastry", "name_zh": "鲫鱼烧", "name_ja": "たい焼き",
                "description": "붕어 모양의 달콤한 팥 또는 크림 빵", "spice_level": 1,
                "tags": {"categories": ["디저트", "빵", "달콤한"], "allergens": ["글루텐", "계란"]}
            },
            {
                "name": "호떡", "name_en": "Sweet Pancake", "name_zh": "糖饼", "name_ja": "ホットク",
                "description": "설탕과 견과류가 들어간 달콤한 팬케이크", "spice_level": 1,
                "tags": {"categories": ["디저트", "팬케이크", "달콤한"], "allergens": ["글루텐", "견과류"]}
            },
            {
                "name": "만두", "name_en": "Dumplings", "name_zh": "饺子", "name_ja": "餃子",
                "description": "고기와 야채가 들어간 찐 또는 구운 만두", "spice_level": 2,
                "tags": {"categories": ["만두", "고기", "야채"], "allergens": ["글루텐"]}
            },
            {
                "name": "튀김", "name_en": "Korean Tempura", "name_zh": "天妇罗", "name_ja": "天ぷら",
                "description": "야채와 해산물을 튀긴 바삭한 요리", "spice_level": 1,
                "tags": {"categories": ["튀김", "야채", "해산물"], "allergens": ["글루텐"]}
            },
            {
                "name": "잔치국수", "name_en": "Banquet Noodles", "name_zh": "宴会面条", "name_ja": "잔치국수",
                "description": "멸치 육수의 따뜻한 국수", "spice_level": 1,
                "tags": {"categories": ["국수", "국물", "따뜻한"], "allergens": ["글루텐"]}
            }
        ]
        
        menu_items = []
        for item_data in menu_items_data:
            menu_item = MenuItem(
                id=uuid.uuid4(),
                market_id=market.id,
                **item_data
            )
            menu_items.append(menu_item)
            db.add(menu_item)
        
        db.flush()
        
        # 3. 가게 생성
        print("🏪 가게 데이터 생성 중...")
        shops_data = [
            {"name": "할머니 빈대떡", "name_en": "Grandma's Bindaetteok", "lat": 37.5703, "lng": 126.9998, "address": "서울 종로구 창경궁로 88"},
            {"name": "김치전 명가", "name_en": "Kimchi Jeon Master", "lat": 37.5705, "lng": 126.9995, "address": "서울 종로구 창경궁로 90"},
            {"name": "떡볶이 천국", "name_en": "Tteokbokki Heaven", "lat": 37.5701, "lng": 127.0001, "address": "서울 종로구 창경궁로 85"},
            {"name": "순대 맛집", "name_en": "Sundae Restaurant", "lat": 37.5707, "lng": 126.9993, "address": "서울 종로구 창경궁로 92"},
            {"name": "김밥 나라", "name_en": "Kimbap Kingdom", "lat": 37.5699, "lng": 127.0003, "address": "서울 종로구 창경궁로 83"},
            {"name": "붕어빵 아저씨", "name_en": "Fish Bread Uncle", "lat": 37.5704, "lng": 126.9997, "address": "서울 종로구 창경궁로 89"},
            {"name": "호떡 할머니", "name_en": "Hotteok Grandma", "lat": 37.5702, "lng": 126.9999, "address": "서울 종로구 창경궁로 87"},
            {"name": "만두 전문점", "name_en": "Dumpling Specialist", "lat": 37.5706, "lng": 126.9994, "address": "서울 종로구 창경궁로 91"},
            {"name": "튀김 마을", "name_en": "Tempura Village", "lat": 37.5700, "lng": 127.0002, "address": "서울 종로구 창경궁로 84"},
            {"name": "국수 한 그릇", "name_en": "One Bowl Noodles", "lat": 37.5708, "lng": 126.9992, "address": "서울 종로구 창경궁로 93"}
        ]
        
        shops = []
        for i, shop_data in enumerate(shops_data):
            shop = Shop(
                id=uuid.uuid4(),
                market_id=market.id,
                **shop_data,
                geom=geo_func.ST_GeogFromText(f'POINT({shop_data["lng"]} {shop_data["lat"]})')
            )
            shops.append(shop)
            db.add(shop)
        
        db.flush()
        
        # 4. 가게별 메뉴 연결
        print("🔗 가게-메뉴 연결 생성 중...")
        import random
        
        for shop in shops:
            # 각 가게마다 3-7개의 메뉴 아이템 판매
            num_menus = random.randint(3, 7)
            selected_menus = random.sample(menu_items, num_menus)
            
            for menu_item in selected_menus:
                shop_menu = ShopMenu(
                    id=uuid.uuid4(),
                    shop_id=shop.id,
                    menu_item_id=menu_item.id,
                    price=random.randint(3000, 15000),  # 3,000원 ~ 15,000원
                    available=True
                )
                db.add(shop_menu)
        
        # 5. 테스트 사용자 생성
        print("👥 테스트 사용자 생성 중...")
        users_data = [
            {
                "display_name": "김민수", "country": "KR", "birth_yyyy_mm": "1990-05",
                "spice_level": 3, "adventure": AdventureLevel.MODERATE, 
                "korean_experience": KoreanExperience.LIVING_IN_KOREA, "locale": "ko"
            },
            {
                "display_name": "John Smith", "country": "US", "birth_yyyy_mm": "1985-08",
                "spice_level": 2, "adventure": AdventureLevel.CONSERVATIVE,
                "korean_experience": KoreanExperience.FIRST_TIME, "locale": "en"
            },
            {
                "display_name": "田中太郎", "country": "JP", "birth_yyyy_mm": "1992-12",
                "spice_level": 4, "adventure": AdventureLevel.ADVENTUROUS,
                "korean_experience": KoreanExperience.SOME_EXPERIENCE, "locale": "ja"
            },
            {
                "display_name": "李小明", "country": "CN", "birth_yyyy_mm": "1988-03",
                "spice_level": 5, "adventure": AdventureLevel.ADVENTUROUS,
                "korean_experience": KoreanExperience.FREQUENT_VISITOR, "locale": "zh"
            },
            {
                "display_name": "Sarah Johnson", "country": "CA", "birth_yyyy_mm": "1995-07",
                "spice_level": 1, "adventure": AdventureLevel.CONSERVATIVE,
                "korean_experience": KoreanExperience.FIRST_TIME, "locale": "en"
            }
        ]
        
        users = []
        for user_data in users_data:
            user = User(
                id=uuid.uuid4(),
                **user_data
            )
            users.append(user)
            db.add(user)
        
        db.flush()
        
        # 6. 좋아요 및 핀 생성
        print("❤️ 좋아요 및 핀 데이터 생성 중...")
        
        for user in users:
            # 각 사용자마다 2-5개의 메뉴에 좋아요
            num_likes = random.randint(2, 5)
            liked_menus = random.sample(menu_items, num_likes)
            
            for menu_item in liked_menus:
                like = Like(
                    id=uuid.uuid4(),
                    user_id=user.id,
                    menu_item_id=menu_item.id
                )
                db.add(like)
                
                # 이벤트 기록
                event = Event(
                    id=uuid.uuid4(),
                    user_id=user.id,
                    action_type=ActionType.LIKE,
                    target_type=TargetType.MENU_ITEM,
                    target_id=menu_item.id
                )
                db.add(event)
            
            # 각 사용자마다 1-3개의 가게나 메뉴에 핀
            num_pins = random.randint(1, 3)
            for _ in range(num_pins):
                if random.choice([True, False]):
                    # 가게 핀
                    shop = random.choice(shops)
                    pin = Pin(
                        id=uuid.uuid4(),
                        user_id=user.id,
                        shop_id=shop.id
                    )
                else:
                    # 메뉴 핀
                    menu_item = random.choice(menu_items)
                    pin = Pin(
                        id=uuid.uuid4(),
                        user_id=user.id,
                        menu_item_id=menu_item.id
                    )
                db.add(pin)
        
        # 7. 샘플 사진 데이터
        print("📸 샘플 사진 데이터 생성 중...")
        
        sample_photos = [
            {
                "s3_key": "photos/sample_bindaetteok.jpg",
                "lat": 37.5703, "lng": 126.9998,
                "taken_at": datetime.utcnow() - timedelta(hours=2),
                "processed": True,
                "parsed_items": {
                    "is_food": True,
                    "food_coverage": 0.8,
                    "detected_foods": [{"name": "빈대떡", "confidence": 0.95}]
                }
            },
            {
                "s3_key": "photos/sample_kimchi_jeon.jpg",
                "lat": 37.5705, "lng": 126.9995,
                "taken_at": datetime.utcnow() - timedelta(hours=1),
                "processed": True,
                "parsed_items": {
                    "is_food": True,
                    "food_coverage": 0.9,
                    "detected_foods": [{"name": "김치전", "confidence": 0.92}]
                }
            }
        ]
        
        for i, photo_data in enumerate(sample_photos):
            photo = Photo(
                id=uuid.uuid4(),
                uploader_user_id=users[i % len(users)].id,
                **photo_data
            )
            db.add(photo)
        
        # 8. 샘플 다이어리
        print("📔 샘플 다이어리 생성 중...")
        
        diary = Diary(
            id=uuid.uuid4(),
            user_id=users[0].id,
            market_id=market.id,
            content="광장시장에서 정말 맛있는 빈대떡을 먹었어요! 바삭바삭하고 고소한 맛이 일품이었습니다.",
            keywords=["맛있는", "바삭바삭", "고소한", "추천"]
        )
        db.add(diary)
        
        # 9. 키워드 리뷰 집계
        print("🏷️ 키워드 리뷰 데이터 생성 중...")
        
        keywords_data = [
            {"keyword": "맛있는", "count": 15},
            {"keyword": "바삭바삭", "count": 8},
            {"keyword": "고소한", "count": 12},
            {"keyword": "매운", "count": 6},
            {"keyword": "달콤한", "count": 9},
            {"keyword": "추천", "count": 20},
            {"keyword": "전통적인", "count": 7},
            {"keyword": "저렴한", "count": 11}
        ]
        
        for keyword_data in keywords_data:
            keyword_review = KeywordReview(
                market_id=market.id,
                **keyword_data
            )
            db.add(keyword_review)
        
        # 모든 변경사항 커밋
        db.commit()
        print("✅ 시드 데이터 생성 완료!")
        
        # 생성된 데이터 요약
        print("\n📊 생성된 데이터 요약:")
        print(f"- 시장: 1개 (광장시장)")
        print(f"- 메뉴 아이템: {len(menu_items)}개")
        print(f"- 가게: {len(shops)}개")
        print(f"- 사용자: {len(users)}명")
        print(f"- 사진: {len(sample_photos)}장")
        print(f"- 다이어리: 1개")
        print(f"- 키워드: {len(keywords_data)}개")
        
    except Exception as e:
        print(f"❌ 시드 데이터 생성 실패: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    create_seed_data()
