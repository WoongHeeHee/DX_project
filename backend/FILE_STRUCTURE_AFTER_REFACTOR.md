# 리팩토링 후 파일 구조

## 개요

이 문서는 사진 처리 시스템 리팩토링 후의 폴더/파일 구조를 명세합니다.

---

## 디렉토리 구조

```
backend/
├── app/
│   ├── api/
│   │   ├── photos.py              # 사진 업로드 API (외부 인터페이스)
│   │   ├── search.py              # 검색 API (저장 없음)
│   │   └── internal.py            # 내부 프록시 엔드포인트 (fallback용)
│   │
│   ├── services/
│   │   ├── photo_processing_service.py    # 전체 워크플로 조립
│   │   ├── vision_service.py              # bbox 탐지 전용
│   │   ├── menu_matcher_service.py       # 메뉴 매칭 전용 (핵심, 단일 진실 소스)
│   │   ├── s3_service.py                  # S3 업로드/다운로드
│   │   └── openai_service.py             # OpenAI 클라이언트 래퍼
│   │
│   ├── utils/
│   │   ├── image_utils.py         # 이미지 crop 유틸리티
│   │   └── geo_utils.py           # 지리적 계산 유틸리티
│   │
│   ├── tasks/
│   │   └── photo_tasks.py         # Celery 비동기 작업 (현재는 동기 처리로 변경됨)
│   │
│   ├── db/
│   │   ├── models.py              # SQLAlchemy 모델
│   │   └── database.py           # DB 연결 설정
│   │
│   └── models/
│       └── schemas.py             # Pydantic 스키마
│
└── [설정 파일들]
```

---

## 파일별 역할

### API 레이어

#### `api/photos.py`
- **역할**: 사진 업로드 관련 외부 인터페이스
- **주요 엔드포인트**:
  - `POST /photos/presign`: presigned URL 발급
  - `POST /photos`: 사진 업로드 완료 처리 (review/report)
- **책임**:
  - 요청 검증
  - Photo 레코드 생성
  - PhotoProcessingService 호출
  - 응답 반환

#### `api/search.py`
- **역할**: 검색 관련 외부 인터페이스
- **주요 엔드포인트**:
  - `POST /search/image-upload`: 이미지 검색 (저장 없음)
- **책임**:
  - 이미지 파일 받기
  - MenuMatcherService 호출
  - 결과 반환 (저장 없음)

#### `api/internal.py`
- **역할**: 내부 프록시 엔드포인트 (fallback용)
- **주요 엔드포인트**:
  - `GET /internal/serve_photo/{photo_id}`: S3 객체 스트리밍
- **책임**:
  - 임시 토큰 검증
  - S3 객체 스트리밍
  - OpenAI Vision API fallback 지원

---

### 서비스 레이어

#### `services/photo_processing_service.py`
- **역할**: 전체 워크플로 조립
- **주요 메서드**:
  - `process_review_photo()`: 리뷰 사진 처리
  - `process_report_photo()`: 제보 사진 처리 (리뷰와 동일)
  - `process_search_photo()`: 검색 사진 처리 (저장 없음)
- **책임**:
  - 원본 사진 다운로드
  - Vision Service로 bbox 탐지
  - Image Utils로 crop 생성
  - Menu Matcher로 메뉴 매칭
  - S3 업로드 및 DB 저장

#### `services/vision_service.py`
- **역할**: bbox 탐지 전용
- **주요 메서드**:
  - `detect_foods_with_bbox()`: 여러 음식 탐지 및 bbox 반환
- **책임**:
  - OpenAI Vision API 호출
  - bbox 좌표 반환 (0~1 정규화)
  - 메뉴 매칭은 담당하지 않음

#### `services/menu_matcher_service.py`
- **역할**: 메뉴 매칭 전용 (핵심, 단일 진실 소스)
- **주요 메서드**:
  - `match_menu()`: 이미지와 텍스트를 사용하여 DB menu_items와 매칭
  - `get_all_menus()`: DB에서 모든 메뉴 리스트 반환
- **책임**:
  - DB menu_items 조회
  - OpenAI GPT-4V를 사용한 메뉴 매칭
  - 최종 메뉴 존재 여부 판정

#### `services/s3_service.py`
- **역할**: S3 업로드/다운로드
- **주요 메서드**:
  - `generate_presigned_download_url()`: 다운로드용 presigned URL 생성
  - `generate_presigned_upload_url()`: 업로드용 presigned URL 생성
  - `upload_file()`: 파일 업로드
  - `download_object_to_bytes()`: 객체 다운로드
  - `verify_presigned_url()`: presigned URL 검증
- **책임**:
  - S3 클라이언트 관리
  - Presigned URL 생성 (TTL 1시간, ResponseContentType 명시)
  - 파일 업로드/다운로드

#### `services/openai_service.py`
- **역할**: OpenAI 클라이언트 래퍼
- **책임**:
  - OpenAI 클라이언트 초기화
  - API 키 관리

---

### 유틸리티 레이어

#### `utils/image_utils.py`
- **역할**: 이미지 crop 유틸리티
- **주요 함수**:
  - `crop_image_by_bbox()`: bbox 좌표를 사용하여 이미지 crop
  - `validate_bbox()`: bbox 좌표 유효성 검증
- **책임**:
  - Pillow를 사용한 이미지 crop
  - 정규화된 좌표를 픽셀 좌표로 변환

#### `utils/geo_utils.py`
- **역할**: 지리적 계산 유틸리티
- **주요 함수**:
  - `find_nearest_shop()`: 가장 가까운 shop 찾기
- **책임**:
  - Haversine 거리 계산
  - Bounding box 최적화

---

### 태스크 레이어

#### `tasks/photo_tasks.py`
- **역할**: Celery 비동기 작업 (현재는 동기 처리로 변경됨)
- **주요 태스크**:
  - `process_photo()`: 사진 처리 메인 작업
  - `generate_thumbnails()`: 썸네일 생성 작업
- **책임**:
  - 비동기 사진 처리 (필요 시)
  - 썸네일 생성

---

### 데이터베이스 레이어

#### `db/models.py`
- **역할**: SQLAlchemy 모델 정의
- **주요 모델**:
  - `Photo`: 사진 테이블
  - `MenuItem`: 메뉴 아이템 테이블
  - `Shop`: 가게 테이블
  - `Market`: 시장 테이블
- **책임**:
  - 데이터베이스 스키마 정의
  - 관계 설정

#### `db/database.py`
- **역할**: DB 연결 설정
- **책임**:
  - 데이터베이스 연결 관리
  - 세션 생성

---

### 스키마 레이어

#### `models/schemas.py`
- **역할**: Pydantic 스키마 정의
- **주요 스키마**:
  - `PhotoUploadRequest`: 사진 업로드 요청
  - `PhotoUploadResponse`: 사진 업로드 응답
  - `PhotoPresignResponse`: presigned URL 응답
  - `ImageSearchRequest`: 이미지 검색 요청
  - `ImageSearchResponse`: 이미지 검색 응답
- **책임**:
  - API 요청/응답 검증
  - 데이터 직렬화/역직렬화

---

## 제거된 파일/기능

### 제거된 기능

1. **check_is_food (음식 판별)**
   - 선택적 기능으로 제거되었습니다.
   - 필요 시 뒷단에서 menu_matcher가 최종 결정합니다.

2. **vision_service.match_menu_from_crop()**
   - menu_matcher로 통일되었습니다.
   - Vision Service는 bbox 탐지만 담당합니다.

3. **중복 메뉴 매칭 로직**
   - menu_matcher 외의 메뉴 존재 판단 로직을 제거했습니다.

### 제거되지 않은 파일 (하위 호환성 유지)

1. **api/photos.py의 기존 엔드포인트**
   - `/uploads/photo-init`: 기존 API (하위 호환성 유지)
   - `/uploads/photo-complete`: 기존 API (하위 호환성 유지)

---

## 데이터 흐름

### Report/Review 사진 처리

```
Client
  ↓
POST /photos/presign
  ↓
POST /photos (photo_type='review' or 'report')
  ↓
PhotoProcessingService.process_review_photo()
  ↓
S3Service.download_object_to_bytes()
  ↓
VisionService.detect_foods_with_bbox()
  ↓
ImageUtils.crop_image_by_bbox() (N개)
  ↓
MenuMatcherService.match_menu() (각 crop마다)
  ↓
S3Service.upload_file() (매칭 성공한 crop만)
  ↓
Photo DB 저장 (매칭 성공한 crop만)
  ↓
Response (saved_photo_ids)
```

### Search 사진 처리

```
Client
  ↓
POST /search/image-upload
  ↓
MenuMatcherService.match_menu()
  ↓
Response (matched_menu or None)
```

---

## 의존성 관계

```
photo_processing_service.py
  ├── vision_service.py (bbox 탐지)
  ├── menu_matcher_service.py (메뉴 매칭)
  ├── s3_service.py (업로드/다운로드)
  ├── image_utils.py (crop)
  └── geo_utils.py (가장 가까운 shop 찾기)

vision_service.py
  └── openai_service.py

menu_matcher_service.py
  └── openai_service.py

s3_service.py
  └── (boto3, AWS SDK)
```

---

## 확장성 고려사항

### 향후 추가 가능한 파일

1. **services/food_classifier_service.py**
   - 음식 판별 전용 서비스 (선택적)
   - 필요 시 추가 가능

2. **services/confidence_scorer_service.py**
   - 신뢰도 점수 계산 서비스
   - menu_matcher 확장 시 추가 가능

3. **utils/bbox_utils.py**
   - bbox 관련 유틸리티
   - 필요 시 추가 가능

---

## 테스트 파일 구조

```
backend/
├── tests/
│   ├── test_photo_processing_service.py
│   ├── test_vision_service.py
│   ├── test_menu_matcher_service.py
│   ├── test_image_utils.py
│   └── test_geo_utils.py
```

---

## 설정 파일

```
backend/
├── .env                    # 환경 변수
├── requirements.txt        # Python 의존성
├── docker-compose.yml      # Docker Compose 설정
└── [기타 설정 파일들]
```

