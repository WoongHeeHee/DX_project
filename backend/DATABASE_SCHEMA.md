# 데이터베이스 스키마 문서

## 개요

이 문서는 시장 탐방 서비스의 데이터베이스 스키마를 정리한 것입니다. 모든 테이블, 필드, 관계, 제약 조건을 포함합니다.

---

## 테이블 목록

1. **users** - 사용자
2. **markets** - 시장
3. **shops** - 가게
4. **menu_items** - 메뉴 아이템
5. **shop_menu** - 가게별 메뉴 (조인 테이블)
6. **photos** - 사진
7. **likes** - 좋아요
8. **pins** - 핀 (북마크)
9. **diaries** - 다이어리
10. **keyword_reviews** - 키워드 리뷰 집계
11. **events** - 사용자 이벤트 (추천 시스템용)

---

## 상세 스키마

### 1. users (사용자)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 사용자 고유 ID |
| google_id | VARCHAR(255) | UNIQUE, NULL | Google OAuth ID |
| display_name | VARCHAR(100) | NOT NULL | 표시 이름 |
| korean_name | VARCHAR(50) | NULL | 한국 이름 |
| email | VARCHAR(255) | NULL | 이메일 |
| country | VARCHAR(2) | NULL | ISO 국가 코드 |
| birth_yyyy_mm | VARCHAR(7) | NULL | 생년월 (YYYY-MM 형식) |
| spice_level | INTEGER | DEFAULT 3 | 매운맛 수준 (1-5) |
| adventure | ENUM | DEFAULT MODERATE | 모험 수준 (conservative, moderate, adventurous) |
| korean_experience | ENUM | DEFAULT FIRST_TIME | 한국 경험 수준 (first_time, some_experience, frequent_visitor, living_in_korea) |
| locale | VARCHAR(5) | DEFAULT 'ko' | 언어 설정 (ko, en, zh, ja) |
| onboarding_completed | BOOLEAN | DEFAULT FALSE | 온보딩 완료 여부 |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |
| updated_at | TIMESTAMP WITH TIME ZONE | NULL | 수정 시간 |

**관계:**
- `photos` (1:N) - 사용자가 업로드한 사진
- `likes` (1:N) - 사용자가 좋아요한 메뉴
- `pins` (1:N) - 사용자가 핀한 가게/메뉴
- `diaries` (1:N) - 사용자가 작성한 다이어리
- `events` (1:N) - 사용자 이벤트

**인덱스:**
- `google_id` (UNIQUE)
- `onboarding_completed` (비회원 필터링용)

---

### 2. markets (시장)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 시장 고유 ID |
| name | VARCHAR(100) | NOT NULL | 시장 이름 (한국어) |
| name_en | VARCHAR(100) | NULL | 시장 이름 (영어) |
| name_zh | VARCHAR(100) | NULL | 시장 이름 (중국어) |
| name_ja | VARCHAR(100) | NULL | 시장 이름 (일본어) |
| description | TEXT | NULL | 시장 설명 |
| silhouette_url | VARCHAR(500) | NULL | 실루엣 이미지 URL |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**관계:**
- `shops` (1:N) - 시장에 속한 가게들
- `menu_items` (1:N) - 시장에서 판매하는 메뉴 아이템들
- `diaries` (1:N) - 시장에 대한 다이어리
- `keyword_reviews` (1:N) - 시장별 키워드 리뷰

---

### 3. shops (가게)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 가게 고유 ID |
| market_id | UUID | FK → markets.id, NOT NULL | 소속 시장 ID |
| name | VARCHAR(100) | NOT NULL | 가게 이름 (한국어) |
| name_en | VARCHAR(100) | NULL | 가게 이름 (영어) |
| name_zh | VARCHAR(100) | NULL | 가게 이름 (중국어) |
| name_ja | VARCHAR(100) | NULL | 가게 이름 (일본어) |
| lat | FLOAT | NOT NULL | 위도 |
| lng | FLOAT | NOT NULL | 경도 |
| geom | GEOGRAPHY(POINT) | NOT NULL | PostGIS 지리 좌표 |
| address | VARCHAR(200) | NULL | 주소 |
| rep_image_url | VARCHAR(500) | NULL | 가게 대표 사진 URL |
| open_time | VARCHAR(5) | NULL | 운영 시작 시간 (HH:MM) |
| close_time | VARCHAR(5) | NULL | 운영 종료 시간 (HH:MM) |
| closed_days | JSONB | NULL | 휴무일 배열 (예: [0, 6] = 일요일, 토요일) |
| last_reported_open_at | TIMESTAMP WITH TIME ZONE | NULL | 마지막 제보/리뷰 시간 |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**관계:**
- `market` (N:1) - 소속 시장
- `shop_menus` (1:N) - 가게에서 판매하는 메뉴
- `pins` (1:N) - 가게를 핀한 사용자들
- `photos` (1:N) - 가게에 대한 사진

**인덱스:**
- `market_id` (FK)
- `geom` (PostGIS GIST 인덱스 - 공간 검색용)
- `last_reported_open_at` (영업 상태 조회용)

**비고:**
- `closed_days`는 JSONB 배열 형식: `[0, 6]` (0=월요일, 6=일요일)
- `geom`은 PostGIS Geography 타입으로, `ST_DWithin` 등을 통한 거리 기반 검색에 사용

---

### 4. menu_items (메뉴 아이템)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 메뉴 아이템 고유 ID |
| market_id | UUID | FK → markets.id, NOT NULL | 소속 시장 ID |
| name | VARCHAR(100) | NOT NULL | 메뉴 이름 (한국어) |
| name_en | VARCHAR(100) | NULL | 메뉴 이름 (영어) |
| name_zh | VARCHAR(100) | NULL | 메뉴 이름 (중국어) |
| name_ja | VARCHAR(100) | NULL | 메뉴 이름 (일본어) |
| description | TEXT | NULL | 메뉴 설명 |
| rep_image_url | VARCHAR(500) | NULL | 메뉴 대표 사진 URL |
| category | VARCHAR(50) | NULL | 카테고리 (Meals, Snacks, Sweets, Drink) |
| tags | JSONB | NULL | 태그 (JSON 객체) |
| spice_level | INTEGER | DEFAULT 1 | 매운맛 수준 (1-5) |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**관계:**
- `market` (N:1) - 소속 시장
- `shop_menus` (1:N) - 해당 메뉴를 판매하는 가게들
- `likes` (1:N) - 메뉴를 좋아요한 사용자들
- `pins` (1:N) - 메뉴를 핀한 사용자들

**인덱스:**
- `market_id` (FK)
- `category` (카테고리 필터링용)
- `spice_level` (매운맛 수준 필터링용)

---

### 5. shop_menu (가게별 메뉴)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 고유 ID |
| shop_id | UUID | FK → shops.id, NOT NULL | 가게 ID |
| menu_item_id | UUID | FK → menu_items.id, NOT NULL | 메뉴 아이템 ID |
| price | INTEGER | NULL | 가격 (원 단위) |
| available | BOOLEAN | DEFAULT TRUE | 판매 가능 여부 |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**관계:**
- `shop` (N:1) - 소속 가게
- `menu_item` (N:1) - 메뉴 아이템

**인덱스:**
- `(shop_id, menu_item_id)` (UNIQUE - 중복 방지)
- `shop_id` (FK)
- `menu_item_id` (FK)
- `available` (판매 가능한 메뉴 필터링용)

**비고:**
- 조인 테이블로, 가게와 메뉴의 다대다 관계를 나타냄
- 같은 메뉴라도 가게마다 가격이 다를 수 있음

---

### 6. photos (사진)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 사진 고유 ID |
| uploader_user_id | UUID | FK → users.id, NULL | 업로더 사용자 ID (비회원 가능) |
| shop_id | UUID | FK → shops.id, NULL | 제보/리뷰된 가게 ID |
| upload_token | VARCHAR(255) | NULL | 비회원용 업로드 토큰 |
| s3_key | VARCHAR(500) | NOT NULL | S3 키 (원본 이미지) |
| thumbnail_s3_key | VARCHAR(500) | NULL | 썸네일 S3 키 |
| lat | FLOAT | NOT NULL | 촬영 위치 위도 |
| lng | FLOAT | NOT NULL | 촬영 위치 경도 |
| taken_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 촬영 시간 |
| processed | BOOLEAN | DEFAULT FALSE | 이미지 처리 완료 여부 |
| parsed_items | JSONB | NULL | 파싱된 음식 정보 (메뉴, bbox 등) |
| photo_type | VARCHAR(20) | NULL | 사진 타입 ('report' 제보용, 'review' 리뷰용) |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**관계:**
- `uploader` (N:1) - 업로더 사용자 (NULL 가능 - 비회원)
- `shop` (N:1) - 제보/리뷰된 가게

**인덱스:**
- `uploader_user_id` (FK, NULL 가능)
- `shop_id` (FK, NULL 가능)
- `upload_token` (비회원 업로드 토큰 조회용)
- `processed` (미처리 사진 조회용)
- `created_at` (최신 사진 조회용)
- `(lat, lng)` (위치 기반 검색용)

**비고:**
- `uploader_user_id`가 NULL인 경우 비회원 제보
- `parsed_items`는 JSONB 형식: `{"menu_name": "떡볶이", "bbox": [...], ...}`

---

### 7. likes (좋아요)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 좋아요 고유 ID |
| user_id | UUID | FK → users.id, NOT NULL | 사용자 ID |
| menu_item_id | UUID | FK → menu_items.id, NOT NULL | 메뉴 아이템 ID |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**관계:**
- `user` (N:1) - 좋아요한 사용자
- `menu_item` (N:1) - 좋아요된 메뉴

**인덱스:**
- `(user_id, menu_item_id)` (UNIQUE - 중복 방지)
- `user_id` (FK)
- `menu_item_id` (FK)
- `created_at` (최신 좋아요 조회용)

**비고:**
- 사용자-메뉴별로 하나의 좋아요만 가능 (UNIQUE 제약)

---

### 8. pins (핀)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 핀 고유 ID |
| user_id | UUID | FK → users.id, NOT NULL | 사용자 ID |
| shop_id | UUID | FK → shops.id, NULL | 핀한 가게 ID |
| menu_item_id | UUID | FK → menu_items.id, NULL | 핀한 메뉴 아이템 ID |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**관계:**
- `user` (N:1) - 핀한 사용자
- `shop` (N:1) - 핀한 가게 (NULL 가능)
- `menu_item` (N:1) - 핀한 메뉴 (NULL 가능)

**인덱스:**
- `user_id` (FK)
- `shop_id` (FK, NULL 가능)
- `menu_item_id` (FK, NULL 가능)
- `created_at` (최신 핀 조회용)

**비고:**
- `shop_id`와 `menu_item_id` 중 하나는 반드시 있어야 함 (체크 제약 필요할 수 있음)

---

### 9. diaries (다이어리)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 다이어리 고유 ID |
| user_id | UUID | FK → users.id, NOT NULL | 작성자 사용자 ID |
| market_id | UUID | FK → markets.id, NOT NULL | 시장 ID |
| content | TEXT | NULL | 다이어리 내용 |
| photo_ids | JSONB | NULL | 관련 사진 ID 배열 |
| keywords | JSONB | NULL | 키워드 배열 |
| created_at | TIMESTAMP WITH TIME ZONE | NOT NULL | 생성 시간 |

**관계:**
- `user` (N:1) - 작성자 사용자
- `market` (N:1) - 관련 시장

**인덱스:**
- `user_id` (FK)
- `market_id` (FK)
- `created_at` (최신 다이어리 조회용)

**비고:**
- `photo_ids`는 JSONB 배열: `["uuid1", "uuid2", ...]`
- `keywords`는 JSONB 배열: `["대부분 현지인들이 방문해요", "한적해요", ...]`

---

### 10. keyword_reviews (키워드 리뷰 집계)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| market_id | UUID | FK → markets.id, PK | 시장 ID |
| keyword | VARCHAR(50) | PK | 키워드 |
| count | INTEGER | DEFAULT 0 | 키워드 선택 횟수 |
| last_updated | TIMESTAMP WITH TIME ZONE | NOT NULL | 마지막 업데이트 시간 |

**관계:**
- `market` (N:1) - 관련 시장

**인덱스:**
- `(market_id, keyword)` (PRIMARY KEY)
- `market_id` (FK)
- `count` (인기 키워드 조회용)

**비고:**
- 복합 기본 키: `(market_id, keyword)`
- 다이어리 작성 시 집계되는 키워드 통계
- Celery Beat를 통한 주기적 집계도 가능

---

### 11. events (사용자 이벤트)

| 컬럼명 | 타입 | 제약 | 설명 |
|--------|------|------|------|
| id | UUID | PK | 이벤트 고유 ID |
| user_id | UUID | FK → users.id, NOT NULL | 사용자 ID |
| action_type | ENUM | NOT NULL | 행동 타입 (photo_upload, like, pin, diary_create, shop_visit) |
| target_type | ENUM | NOT NULL | 대상 타입 (menu_item, shop, photo, diary) |
| target_id | UUID | NOT NULL | 대상 ID |
| timestamp | TIMESTAMP WITH TIME ZONE | NOT NULL | 이벤트 발생 시간 |

**관계:**
- `user` (N:1) - 이벤트를 발생시킨 사용자

**인덱스:**
- `user_id` (FK)
- `action_type` (이벤트 타입 필터링용)
- `target_type` (대상 타입 필터링용)
- `timestamp` (시간대별 이벤트 조회용)
- `(user_id, timestamp)` (사용자별 최근 이벤트 조회용)

**비고:**
- 추천 시스템을 위한 사용자 행동 로그
- 협업 필터링 등에 활용 가능

---

## Enum 타입

### AdventureLevel (모험 수준)
- `conservative` - 안정형
- `moderate` - 중간
- `adventurous` - 도전형

### KoreanExperience (한국 경험 수준)
- `first_time` - 뉴비 (최초 방문)
- `some_experience` - 즐겜러 (일부 경험)
- `frequent_visitor` - 고인물 (자주 방문)
- `living_in_korea` - 거주자 (한국 거주)

### ActionType (행동 타입)
- `photo_upload` - 사진 업로드
- `like` - 좋아요
- `pin` - 핀
- `diary_create` - 다이어리 생성
- `shop_visit` - 가게 방문

### TargetType (대상 타입)
- `menu_item` - 메뉴 아이템
- `shop` - 가게
- `photo` - 사진
- `diary` - 다이어리

---

## 제약 조건 및 비고

### 1. 외래 키 제약
- 모든 FK는 `ON DELETE CASCADE` 또는 `ON DELETE SET NULL` 처리 필요
- `photos.uploader_user_id`는 NULL 가능 (비회원)
- `pins`에서 `shop_id`와 `menu_item_id` 중 하나는 필수 (애플리케이션 레벨 검증)

### 2. 유니크 제약
- `users.google_id` (UNIQUE)
- `likes(user_id, menu_item_id)` (UNIQUE)
- `keyword_reviews(market_id, keyword)` (PRIMARY KEY)

### 3. 공간 데이터
- `shops.geom`은 PostGIS Geography 타입 사용
- `ST_DWithin`, `ST_Distance` 등으로 거리 기반 검색 가능

### 4. JSONB 필드
- `shops.closed_days`: 배열 형식
- `photos.parsed_items`: 객체 형식 (메뉴 정보, bbox 등)
- `diaries.photo_ids`: 배열 형식
- `diaries.keywords`: 배열 형식

### 5. 타임존
- 모든 `TIMESTAMP WITH TIME ZONE` 필드는 UTC로 저장
- 클라이언트에서 표시 시 로컬 타임존으로 변환

---

## 인덱스 전략

### 고성능 쿼리를 위한 인덱스
1. **공간 검색**: `shops.geom` (GIST 인덱스)
2. **시간 기반 조회**: `photos.created_at`, `shops.last_reported_open_at`
3. **사용자별 조회**: `photos.uploader_user_id`, `likes.user_id`, `pins.user_id`
4. **시장/가게별 조회**: `shops.market_id`, `menu_items.market_id`
5. **카테고리 필터링**: `menu_items.category`
6. **매운맛 수준 필터링**: `menu_items.spice_level`

---

## 마이그레이션

모든 스키마 변경은 Alembic 마이그레이션을 통해 관리됩니다.
- 마이그레이션 파일 위치: `backend/alembic/versions/`
- 최신 마이그레이션 확인: `alembic current`
- 마이그레이션 실행: `alembic upgrade head`

---

## 참고 사항

1. **비회원 지원**: 사진 업로드는 `upload_token`을 통해 비회원도 가능
2. **이미지 처리**: `photos.processed` 플래그로 Celery 작업 완료 여부 추적
3. **영업 상태**: `shops.last_reported_open_at`을 통한 실시간 영업 상태 추정
4. **키워드 집계**: `keyword_reviews`는 다이어리 작성 시 즉시 업데이트 + Celery Beat 주기적 집계

