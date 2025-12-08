# API 명세서

## 목차

1. [인증 (Authentication)](#인증-authentication)
2. [사용자 (Users)](#사용자-users)
3. [시장 (Markets)](#시장-markets)
4. [가게 (Shops)](#가게-shops)
5. [사진 업로드 (Photos)](#사진-업로드-photos)
6. [검색 (Search)](#검색-search)
7. [추천 (Recommendations)](#추천-recommendations)
8. [다이어리 (Diary)](#다이어리-diary)
9. [지도 - 시장 (Market Photos)](#지도---시장-market-photos)
10. [공통 응답 형식](#공통-응답-형식)
11. [에러 코드](#에러-코드)

---

## 기본 정보

- **Base URL**: `http://localhost:8000` (개발 환경)
- **API Version**: `1.0.0`
- **인증 방식**: JWT Bearer Token
- **Content-Type**: `application/json`

---

## 인증 (Authentication)

### 1. Google OAuth 로그인

#### Endpoint
```
POST /auth/google
```

#### Description
Google OAuth를 통한 사용자 인증 및 JWT 토큰 발급

#### Method
`POST`

#### Request Headers
```
Content-Type: application/json
```

#### Request Body
```json
{
  "code": "google_id_token_string",
  "redirect_uri": "http://localhost:3000/callback"
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| code | string | ✅ | Google ID Token |
| redirect_uri | string | ✅ | 리디렉션 URI |

#### Response Example
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

#### Response Schema
| 필드 | 타입 | 설명 |
|------|------|------|
| access_token | string | JWT 액세스 토큰 |
| token_type | string | "bearer" |
| expires_in | integer | 토큰 만료 시간 (초) |

#### Status Codes
- `200 OK`: 인증 성공
- `400 Bad Request`: Google 인증 실패
- `500 Internal Server Error`: 서버 오류

#### Notes
- 첫 로그인 시 자동으로 사용자 계정 생성
- 기존 사용자는 로그인만 수행
- 토큰은 30분간 유효 (설정 가능)

---

### 2. 현재 사용자 정보 조회

#### Endpoint
```
GET /auth/me
```

#### Description
현재 로그인한 사용자의 정보 조회

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Request Body
없음

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "display_name": "John Doe",
  "korean_name": "홍록기",
  "email": "john@example.com",
  "country": "US",
  "birth_yyyy_mm": "1990-01",
  "spice_level": 3,
  "adventure": "moderate",
  "korean_experience": "first_time",
  "locale": "en",
  "onboarding_completed": false,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": null
}
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

#### Notes
- 인증 필수 엔드포인트

---

### 3. 토큰 갱신

#### Endpoint
```
POST /auth/refresh
```

#### Description
JWT 토큰 갱신

#### Method
`POST`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Request Body
없음

#### Response Example
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

#### Status Codes
- `200 OK`: 토큰 갱신 성공
- `401 Unauthorized`: 인증 실패

---

## 사용자 (Users)

### 1. 프로필 조회

#### Endpoint
```
GET /users/profile
```

#### Description
현재 사용자의 프로필 정보 조회

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "display_name": "John Doe",
  "korean_name": "홍록기",
  "email": "john@example.com",
  "country": "US",
  "birth_yyyy_mm": "1990-01",
  "spice_level": 3,
  "adventure": "moderate",
  "korean_experience": "first_time",
  "locale": "en",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

---

### 2. 프로필 업데이트

#### Endpoint
```
PUT /users/profile
```

#### Description
사용자 프로필 정보 업데이트

#### Method
`PUT`

#### Request Headers
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

#### Request Body
```json
{
  "display_name": "Jane Doe",
  "korean_name": "김준호",
  "country": "KR",
  "birth_yyyy_mm": "1995-05",
  "spice_level": 4,
  "adventure": "adventurous",
  "korean_experience": "some_experience",
  "locale": "ko"
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| display_name | string | ❌ | 표시 이름 |
| korean_name | string | ❌ | 한국 이름 |
| country | string | ❌ | 국가 코드 (ISO 2자) |
| birth_yyyy_mm | string | ❌ | 생년월 (YYYY-MM) |
| spice_level | integer | ❌ | 매운맛 수준 (1-5) |
| adventure | string | ❌ | 모험 수준 (conservative, moderate, adventurous) |
| korean_experience | string | ❌ | 한국 경험 수준 |
| locale | string | ❌ | 언어 (ko, en, zh, ja) |

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "display_name": "Jane Doe",
  "korean_name": "김준호",
  ...
}
```

#### Status Codes
- `200 OK`: 업데이트 성공
- `400 Bad Request`: 잘못된 입력 값
- `401 Unauthorized`: 인증 실패

---

### 3. 온보딩 완료

#### Endpoint
```
POST /users/onboarding
```

#### Description
온보딩 정보 입력 및 완료 처리

#### Method
`POST`

#### Request Headers
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

#### Request Body
```json
{
  "country": "US",
  "birth_yyyy_mm": "1990-01",
  "spice_level": 3,
  "adventure": "moderate",
  "korean_experience": "first_time"
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| country | string | ✅ | 국가 코드 |
| birth_yyyy_mm | string | ✅ | 생년월 (YYYY-MM) |
| spice_level | integer | ✅ | 매운맛 수준 (1-5) |
| adventure | string | ✅ | 모험 수준 |
| korean_experience | string | ✅ | 한국 경험 수준 |

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "display_name": "John Doe",
  "country": "US",
  "birth_yyyy_mm": "1990-01",
  "spice_level": 3,
  "adventure": "moderate",
  "korean_experience": "first_time",
  "onboarding_completed": true,
  ...
}
```

#### Status Codes
- `200 OK`: 온보딩 완료
- `400 Bad Request`: 필수 필드 누락
- `401 Unauthorized`: 인증 실패

#### Notes
- 온보딩 완료 후 `onboarding_completed`가 `true`로 설정됨
- 필수 필드: country, birth_yyyy_mm, spice_level, adventure, korean_experience

---

### 4. 한국 이름 생성

#### Endpoint
```
POST /users/generate-korean-name
```

#### Description
사용자 원본 이름으로부터 한국 이름 생성

#### Method
`POST`

#### Request Headers
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

#### Request Body
```json
{
  "input_name": "John Doe"
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| input_name | string | ✅ | 원본 이름 (영어, 중국어, 일본어 등) |

#### Response Example
```json
{
  "success": true,
  "korean_name": "홍록기",
  "english_pronunciation": "Hong-Loggi",
  "message": "한국 이름이 성공적으로 생성되었습니다"
}
```

#### Response Schema
| 필드 | 타입 | 설명 |
|------|------|------|
| success | boolean | 성공 여부 |
| korean_name | string | 생성된 한국 이름 |
| english_pronunciation | string | 영어 발음 |
| message | string | 응답 메시지 |

#### Status Codes
- `200 OK`: 생성 성공
- `400 Bad Request`: 잘못된 입력
- `401 Unauthorized`: 인증 실패
- `500 Internal Server Error`: OpenAI API 오류

#### Notes
- OpenAI GPT-4o 모델 사용
- 생성된 한국 이름은 자동으로 사용자 프로필에 저장되지 않음 (별도 업데이트 필요)

---

### 5. 사용자 선호도 조회

#### Endpoint
```
GET /users/preferences
```

#### Description
사용자의 선호도 정보 조회

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Response Example
```json
{
  "spice_level": 3,
  "adventure": "moderate",
  "korean_experience": "first_time",
  "locale": "en",
  "country": "US"
}
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

---

### 6. 계정 삭제

#### Endpoint
```
DELETE /users/account
```

#### Description
사용자 계정 삭제

#### Method
`DELETE`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Response Example
```json
{
  "success": true,
  "message": "계정이 성공적으로 삭제되었습니다"
}
```

#### Status Codes
- `200 OK`: 삭제 성공
- `401 Unauthorized`: 인증 실패

#### Notes
- 계정 삭제 시 업로드한 사진의 `uploader_user_id`는 NULL로 설정 (익명화)
- 실제 삭제는 소프트 삭제 방식 고려 가능

---

## 시장 (Markets)

### 1. 시장 목록 조회

#### Endpoint
```
GET /markets/
```

#### Description
모든 시장 목록 조회

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "광장시장",
    "name_en": "Gwangjang Market",
    "name_zh": "广藏市场",
    "name_ja": "広蔵市場",
    "description": "서울의 대표적인 전통시장",
    "silhouette_url": "https://example.com/silhouette.jpg",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### Status Codes
- `200 OK`: 성공

---

### 2. 시장 상세 조회

#### Endpoint
```
GET /markets/{market_id}
```

#### Description
특정 시장의 상세 정보 조회

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ✅ | 시장 ID |

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "광장시장",
  "name_en": "Gwangjang Market",
  "name_zh": "广藏市场",
  "name_ja": "広蔵市場",
  "description": "서울의 대표적인 전통시장",
  "silhouette_url": "https://example.com/silhouette.jpg",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 시장을 찾을 수 없음

---

### 3. 시장 메뉴 아이템 조회

#### Endpoint
```
GET /markets/{market_id}/menu-items
```

#### Description
특정 시장에서 판매하는 메뉴 아이템 목록 조회

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ✅ | 시장 ID |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "market_id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "떡볶이",
    "name_en": "Tteokbokki",
    "description": "쫄깃한 떡과 매콤한 양념",
    "rep_image_url": "https://example.com/tteokbokki.jpg",
    "category": "Meals",
    "spice_level": 3,
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 시장을 찾을 수 없음

---

### 4. 시장 통계 조회

#### Endpoint
```
GET /markets/{market_id}/stats
```

#### Description
시장 통계 정보 조회 (가게 수, 메뉴 수, 최근 사진 수, 인기 키워드)

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ✅ | 시장 ID |

#### Response Example
```json
{
  "total_shops": 150,
  "total_menu_items": 300,
  "recent_photos_count": 50,
  "popular_keywords": [
    {
      "keyword": "대부분 현지인들이 방문해요",
      "count": 45
    },
    {
      "keyword": "한적해요",
      "count": 30
    }
  ]
}
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 시장을 찾을 수 없음

---

## 가게 (Shops)

### 1. 근처 가게 검색

#### Endpoint
```
POST /shops/nearby
```

#### Description
현재 위치 기준 반경 내 가게 검색 (PostGIS 사용)

#### Method
`POST`

#### Request Headers
```
Content-Type: application/json
```

#### Request Body
```json
{
  "lat": 37.5665,
  "lng": 126.9780,
  "radius_meters": 5,
  "market_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| lat | float | ✅ | 위도 (-90 ~ 90) |
| lng | float | ✅ | 경도 (-180 ~ 180) |
| radius_meters | integer | ✅ | 반경 (미터, 1~1000) |
| market_id | string (UUID) | ❌ | 시장 ID (선택) |

#### Response Example
```json
{
  "success": true,
  "shops": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "market_id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "명동 떡볶이집",
      "name_en": "Myeongdong Tteokbokki",
      "lat": 37.5665,
      "lng": 126.9780,
      "address": "서울특별시 중구 명동",
      "distance_meters": 3.5,
      "last_reported_open_at": "2024-01-01T10:00:00Z",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total_count": 1
}
```

#### Status Codes
- `200 OK`: 성공
- `400 Bad Request`: 잘못된 입력 값

#### Notes
- PostGIS `ST_DWithin` 함수 사용
- 거리순 정렬로 반환

---

### 2. 가게 상세 조회

#### Endpoint
```
GET /shops/{shop_id}
```

#### Description
특정 가게의 상세 정보 조회

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| shop_id | string (UUID) | ✅ | 가게 ID |

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "market_id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "명동 떡볶이집",
  "name_en": "Myeongdong Tteokbokki",
  "lat": 37.5665,
  "lng": 126.9780,
  "address": "서울특별시 중구 명동",
  "rep_image_url": "https://example.com/shop.jpg",
  "open_time": "09:00",
  "close_time": "22:00",
  "closed_days": [0, 6],
  "last_reported_open_at": "2024-01-01T10:00:00Z",
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 가게를 찾을 수 없음

---

### 3. 가게 메뉴 조회

#### Endpoint
```
GET /shops/{shop_id}/menu
```

#### Description
가게에서 판매하는 메뉴 목록 조회

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| shop_id | string (UUID) | ✅ | 가게 ID |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "market_id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "떡볶이",
    "name_en": "Tteokbokki",
    "description": "쫄깃한 떡과 매콤한 양념",
    "rep_image_url": "https://example.com/tteokbokki.jpg",
    "category": "Meals",
    "spice_level": 3,
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 가게를 찾을 수 없음

#### Notes
- `available = true`인 메뉴만 반환

---

### 4. 가게 영업 상태 보고

#### Endpoint
```
PUT /shops/{shop_id}/report-open
```

#### Description
가게 영업 상태 보고 (사진 업로드 시 호출)

#### Method
`PUT`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| shop_id | string (UUID) | ✅ | 가게 ID |

#### Response Example
```json
{
  "success": true,
  "message": "가게 영업 상태가 업데이트되었습니다"
}
```

#### Status Codes
- `200 OK`: 업데이트 성공
- `404 Not Found`: 가게를 찾을 수 없음

#### Notes
- `last_reported_open_at` 필드가 현재 시간으로 업데이트됨

---

### 5. 가게 목록 조회

#### Endpoint
```
GET /shops/
```

#### Description
가게 목록 조회 (필터링 및 페이지네이션 지원)

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ❌ | 시장 ID로 필터링 |
| limit | integer | ❌ | 최대 반환 개수 (기본값: 100) |
| offset | integer | ❌ | 오프셋 (기본값: 0) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "market_id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "명동 떡볶이집",
    "lat": 37.5665,
    "lng": 126.9780,
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### Status Codes
- `200 OK`: 성공

---

## 사진 업로드 (Photos)

### 1. 사진 업로드 초기화

#### Endpoint
```
POST /uploads/photo-init
```

#### Description
사진 업로드를 위한 presigned URL 생성

#### Method
`POST`

#### Request Headers
```
Content-Type: application/json
Authorization: Bearer {access_token}  (선택 - 회원인 경우)
```

#### Request Body
```json
{
  "lat": 37.5665,
  "lng": 126.9780,
  "taken_at": "2024-01-01T10:00:00Z",
  "is_member": true
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| lat | float | ✅ | 촬영 위치 위도 |
| lng | float | ✅ | 촬영 위치 경도 |
| taken_at | datetime | ✅ | 촬영 시간 (ISO 8601) |
| is_member | boolean | ✅ | 회원 여부 |

#### Response Example
```json
{
  "success": true,
  "presigned_url": "https://s3.amazonaws.com/bucket/photos/...",
  "upload_token": "550e8400-e29b-41d4-a716-446655440000",
  "s3_key": "photos/20240101_100000_abc123.jpg",
  "message": "사진 업로드 URL이 생성되었습니다"
}
```

#### Response Schema
| 필드 | 타입 | 설명 |
|------|------|------|
| success | boolean | 성공 여부 |
| presigned_url | string | S3 presigned 업로드 URL |
| upload_token | string | 업로드 토큰 (비회원용) |
| s3_key | string | S3 키 |
| message | string | 응답 메시지 |

#### Status Codes
- `200 OK`: 성공
- `400 Bad Request`: 잘못된 입력 값
- `500 Internal Server Error`: S3 URL 생성 실패

#### Notes
- presigned URL은 1시간 동안 유효
- 비회원인 경우 `upload_token`이 생성됨
- 회원인 경우 `Authorization` 헤더 필요

---

### 2. 사진 업로드 완료

#### Endpoint
```
POST /uploads/photo-complete
```

#### Description
S3에 사진 업로드 완료 후 서버에 알림

#### Method
`POST`

#### Request Headers
```
Content-Type: application/json
Authorization: Bearer {access_token}  (선택 - 회원인 경우)
```

#### Request Body
```json
{
  "upload_token": "550e8400-e29b-41d4-a716-446655440000",
  "s3_key": "photos/20240101_100000_abc123.jpg",
  "lat": 37.5665,
  "lng": 126.9780,
  "taken_at": "2024-01-01T10:00:00Z",
  "uploader_user_id": "123e4567-e89b-12d3-a456-426614174000",
  "photo_type": "report"
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| upload_token | string | ✅ | 업로드 토큰 |
| s3_key | string | ✅ | S3 키 |
| lat | float | ✅ | 촬영 위치 위도 |
| lng | float | ✅ | 촬영 위치 경도 |
| taken_at | datetime | ✅ | 촬영 시간 |
| uploader_user_id | string (UUID) | ❌ | 업로더 사용자 ID |
| photo_type | string | ❌ | 사진 타입 ('report' 또는 'review') |

#### Response Example
```json
{
  "success": true,
  "message": "사진이 성공적으로 업로드되었습니다. 처리 중입니다."
}
```

#### Status Codes
- `200 OK`: 업로드 완료 처리 성공
- `400 Bad Request`: 잘못된 입력 값
- `500 Internal Server Error`: 처리 실패

#### Notes
- 업로드 완료 후 Celery 작업 큐에 이미지 처리 작업 추가
- 이미지 분석, 썸네일 생성 등은 비동기로 처리됨

---

### 3. 제보 완료

#### Endpoint
```
POST /uploads/report-complete
```

#### Description
제보 완료 처리: 가게 선택 후 shop_id 저장 및 영업 상태 업데이트

#### Method
`POST`

#### Request Headers
```
Content-Type: application/json
```

#### Request Body
```json
{
  "upload_token": "550e8400-e29b-41d4-a716-446655440000",
  "shop_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| upload_token | string | ✅ | 업로드 토큰 |
| shop_id | string (UUID) | ✅ | 선택한 가게 ID |

#### Response Example
```json
{
  "success": true,
  "message": "제보가 성공적으로 완료되었습니다"
}
```

#### Status Codes
- `200 OK`: 제보 완료 성공
- `404 Not Found`: 사진 또는 가게를 찾을 수 없음
- `500 Internal Server Error`: 처리 실패

#### Notes
- 사진의 `shop_id` 필드가 업데이트됨
- 가게의 `last_reported_open_at` 필드가 현재 시간으로 업데이트됨

---

### 4. 사진 정보 조회

#### Endpoint
```
GET /uploads/photo/{photo_id}
```

#### Description
특정 사진의 정보 조회

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| photo_id | string (UUID) | ✅ | 사진 ID |

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "s3_key": "photos/20240101_100000_abc123.jpg",
  "thumbnail_s3_key": "thumbnails/20240101_100000_abc123_300x300.jpg",
  "lat": 37.5665,
  "lng": 126.9780,
  "taken_at": "2024-01-01T10:00:00Z",
  "processed": true,
  "parsed_items": {
    "menu_name": "떡볶이",
    "bbox": [[10, 20, 100, 120]]
  },
  "created_at": "2024-01-01T10:00:05Z"
}
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 사진을 찾을 수 없음

---

### 5. 내 사진 목록 조회

#### Endpoint
```
GET /uploads/my-photos
```

#### Description
현재 사용자가 업로드한 사진 목록 조회

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| limit | integer | ❌ | 최대 반환 개수 (기본값: 20) |
| offset | integer | ❌ | 오프셋 (기본값: 0) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "s3_key": "photos/20240101_100000_abc123.jpg",
    "lat": 37.5665,
    "lng": 126.9780,
    "taken_at": "2024-01-01T10:00:00Z",
    "processed": true,
    "created_at": "2024-01-01T10:00:05Z"
  }
]
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

---

### 6. 사진 삭제

#### Endpoint
```
DELETE /uploads/photo/{photo_id}
```

#### Description
사진 삭제 (S3 및 DB)

#### Method
`DELETE`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| photo_id | string (UUID) | ✅ | 사진 ID |

#### Response Example
```json
{
  "success": true,
  "message": "사진이 성공적으로 삭제되었습니다"
}
```

#### Status Codes
- `200 OK`: 삭제 성공
- `404 Not Found`: 사진을 찾을 수 없거나 삭제 권한 없음
- `401 Unauthorized`: 인증 실패

#### Notes
- 본인이 업로드한 사진만 삭제 가능
- S3의 원본 이미지와 썸네일 모두 삭제됨

---

## 검색 (Search)

### 1. 이미지/텍스트 검색

#### Endpoint
```
POST /search/image
```

#### Description
이미지, 텍스트, 또는 둘 다를 이용한 음식 검색

#### Method
`POST`

#### Request Headers
```
Content-Type: application/json
```

#### Request Body
```json
{
  "image_url": "https://example.com/food.jpg",
  "user_text": "매운 떡볶이",
  "lat": 37.5665,
  "lng": 126.9780
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| image_url | string | ❌ | 이미지 URL (image_url 또는 user_text 중 하나 필수) |
| user_text | string | ❌ | 음식에 대한 텍스트 설명 |
| lat | float | ❌ | 현재 위치 위도 (근처 가게 검색용) |
| lng | float | ❌ | 현재 위치 경도 |

#### Response Example
```json
{
  "success": true,
  "results": [
    {
      "menu_item": {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "name": "떡볶이",
        "name_en": "Tteokbokki",
        "description": "쫄깃한 떡과 매콤한 양념",
        "rep_image_url": "https://example.com/tteokbokki.jpg",
        "category": "Meals",
        "spice_level": 3
      },
      "confidence": 1.0,
      "shops_nearby": [
        {
          "id": "123e4567-e89b-12d3-a456-426614174000",
          "name": "명동 떡볶이집",
          "lat": 37.5665,
          "lng": 126.9780,
          "distance_meters": 50.5
        }
      ]
    }
  ],
  "message": "'떡볶이' 메뉴를 찾았습니다"
}
```

#### Status Codes
- `200 OK`: 검색 성공
- `400 Bad Request`: image_url과 user_text 모두 없음
- `500 Internal Server Error`: 검색 처리 실패

#### Notes
- `menu_matcher` 서비스를 통해 메뉴 매칭
- 위치 정보가 제공되면 근처 가게도 함께 반환 (최대 5개)

---

### 2. 메뉴 아이템 텍스트 검색

#### Endpoint
```
GET /search/menu-items
```

#### Description
메뉴 아이템 텍스트 검색

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| q | string | ❌ | 검색어 (이름 또는 설명) |
| market_id | string (UUID) | ❌ | 시장 ID로 필터링 |
| spice_level_max | integer | ❌ | 최대 매운맛 수준 (기본값: 5) |
| limit | integer | ❌ | 최대 반환 개수 (기본값: 20) |
| offset | integer | ❌ | 오프셋 (기본값: 0) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "떡볶이",
    "name_en": "Tteokbokki",
    "description": "쫄깃한 떡과 매콤한 양념",
    "rep_image_url": "https://example.com/tteokbokki.jpg",
    "category": "Meals",
    "spice_level": 3
  }
]
```

#### Status Codes
- `200 OK`: 성공

---

### 3. 인기 메뉴 조회

#### Endpoint
```
GET /search/popular-menus
```

#### Description
인기 메뉴 조회 (좋아요 수 기준)

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ❌ | 시장 ID로 필터링 |
| limit | integer | ❌ | 최대 반환 개수 (기본값: 10) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "떡볶이",
    "name_en": "Tteokbokki",
    "description": "쫄깃한 떡과 매콤한 양념",
    "rep_image_url": "https://example.com/tteokbokki.jpg",
    "category": "Meals",
    "spice_level": 3
  }
]
```

#### Status Codes
- `200 OK`: 성공

---

### 4. 트렌딩 키워드 조회

#### Endpoint
```
GET /search/trending-keywords
```

#### Description
트렌딩 키워드 조회 (다이어리에서 선택된 키워드 집계)

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ❌ | 시장 ID로 필터링 |
| limit | integer | ❌ | 최대 반환 개수 (기본값: 10) |

#### Response Example
```json
[
  {
    "keyword": "대부분 현지인들이 방문해요",
    "count": 45,
    "market_id": "123e4567-e89b-12d3-a456-426614174000"
  },
  {
    "keyword": "한적해요",
    "count": 30,
    "market_id": "123e4567-e89b-12d3-a456-426614174000"
  }
]
```

#### Status Codes
- `200 OK`: 성공

---

## 추천 (Recommendations)

### 1. 사용자 맞춤 추천

#### Endpoint
```
GET /recommendations/
```

#### Description
사용자 맞춤 메뉴 추천 (국적-나이 기반)

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| limit | integer | ❌ | 최대 반환 개수 (기본값: 10) |
| category | string | ❌ | 카테고리 필터 (Meals, Snacks, Sweets, Drink) |

#### Response Example
```json
{
  "success": true,
  "recommendations": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "떡볶이",
      "name_en": "Tteokbokki",
      "description": "쫄깃한 떡과 매콤한 양념",
      "rep_image_url": "https://example.com/tteokbokki.jpg",
      "category": "Meals",
      "spice_level": 3
    }
  ],
  "recommendation_type": "hybrid",
  "message": "10개의 추천 메뉴를 찾았습니다"
}
```

#### Response Schema
| 필드 | 타입 | 설명 |
|------|------|------|
| success | boolean | 성공 여부 |
| recommendations | array | 추천 메뉴 목록 |
| recommendation_type | string | 추천 타입 ("personalized", "hybrid", "popular") |
| message | string | 응답 메시지 |

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

#### Notes
- 사용자의 `nationality`와 `birth`만 활용하여 추천
- 개인 맞춤 → 국적-나이별 트렌드 → 전체 인기 순으로 추천

---

### 2. 국적-나이별 트렌드 추천

#### Endpoint
```
GET /recommendations/nationality-age-trend
```

#### Description
특정 국적과 나이대의 트렌드 메뉴 추천

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| country | string | ❌ | 국가 코드 (없으면 현재 사용자 정보 사용) |
| birth_yyyy_mm | string | ❌ | 생년월 (YYYY-MM, 없으면 현재 사용자 정보 사용) |
| limit | integer | ❌ | 최대 반환 개수 (기본값: 3) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "떡볶이",
    "name_en": "Tteokbokki",
    "description": "쫄깃한 떡과 매콤한 양념",
    "rep_image_url": "https://example.com/tteokbokki.jpg",
    "category": "Meals",
    "spice_level": 3
  }
]
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

---

### 3. 트렌딩 메뉴 추천

#### Endpoint
```
GET /recommendations/trending
```

#### Description
최근 7일간 트렌딩 메뉴 추천 (좋아요 수 기준)

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| limit | integer | ❌ | 최대 반환 개수 (기본값: 10) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "떡볶이",
    "name_en": "Tteokbokki",
    "description": "쫄깃한 떡과 매콤한 양념",
    "rep_image_url": "https://example.com/tteokbokki.jpg",
    "category": "Meals",
    "spice_level": 3
  }
]
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

---

### 4. 초보자 추천

#### Endpoint
```
GET /recommendations/for-beginners
```

#### Description
한국 음식 초보자를 위한 추천 (낮은 매운맛 수준)

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| limit | integer | ❌ | 최대 반환 개수 (기본값: 10) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "김밥",
    "name_en": "Kimbap",
    "description": "맛있는 김밥",
    "rep_image_url": "https://example.com/kimbap.jpg",
    "category": "Meals",
    "spice_level": 1
  }
]
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

---

### 5. 추천 피드백 제출

#### Endpoint
```
POST /recommendations/feedback
```

#### Description
추천에 대한 피드백 제출

#### Method
`POST`

#### Request Headers
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

#### Request Body
```json
{
  "menu_item_id": "123e4567-e89b-12d3-a456-426614174000",
  "feedback": "like"
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| menu_item_id | string (UUID) | ✅ | 메뉴 아이템 ID |
| feedback | string | ✅ | 피드백 타입 ("like", "dislike", "not_interested") |

#### Response Example
```json
{
  "success": true,
  "message": "피드백이 기록되었습니다"
}
```

#### Status Codes
- `200 OK`: 피드백 기록 성공
- `401 Unauthorized`: 인증 실패

#### Notes
- 피드백은 `events` 테이블에 기록됨
- "like"인 경우 `likes` 테이블에도 추가됨

---

## 다이어리 (Diary)

### 1. 다이어리 생성

#### Endpoint
```
POST /diary/
```

#### Description
다이어리 생성

#### Method
`POST`

#### Request Headers
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

#### Request Body
```json
{
  "market_id": "123e4567-e89b-12d3-a456-426614174000",
  "content": "오늘 광장시장에서 맛있게 먹었어요!",
  "photo_ids": ["123e4567-e89b-12d3-a456-426614174000"],
  "keywords": ["대부분 현지인들이 방문해요", "한적해요"]
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| market_id | string (UUID) | ✅ | 시장 ID |
| content | string | ❌ | 다이어리 내용 |
| photo_ids | array of UUID | ❌ | 관련 사진 ID 배열 |
| keywords | array of string | ✅ | 키워드 배열 (최소 1개) |

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "market_id": "123e4567-e89b-12d3-a456-426614174000",
  "content": "오늘 광장시장에서 맛있게 먹었어요!",
  "photo_ids": ["123e4567-e89b-12d3-a456-426614174000"],
  "keywords": ["대부분 현지인들이 방문해요", "한적해요"],
  "created_at": "2024-01-01T10:00:00Z"
}
```

#### Status Codes
- `200 OK`: 생성 성공
- `400 Bad Request`: 필수 필드 누락 (키워드 최소 1개 필요)
- `401 Unauthorized`: 인증 실패
- `404 Not Found`: 시장을 찾을 수 없음

#### Notes
- 키워드는 최소 1개 이상 필수
- 키워드는 `keyword_reviews` 테이블에 즉시 집계됨
- 이벤트가 `events` 테이블에 기록됨

---

### 2. 내 다이어리 목록 조회

#### Endpoint
```
GET /diary/my
```

#### Description
현재 사용자가 작성한 다이어리 목록 조회

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| limit | integer | ❌ | 최대 반환 개수 (기본값: 20) |
| offset | integer | ❌ | 오프셋 (기본값: 0) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "market_id": "123e4567-e89b-12d3-a456-426614174000",
    "content": "오늘 광장시장에서 맛있게 먹었어요!",
    "photo_ids": ["123e4567-e89b-12d3-a456-426614174000"],
    "keywords": ["대부분 현지인들이 방문해요", "한적해요"],
    "created_at": "2024-01-01T10:00:00Z"
  }
]
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

---

### 3. 다이어리 상세 조회

#### Endpoint
```
GET /diary/{diary_id}
```

#### Description
특정 다이어리의 상세 정보 조회

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| diary_id | string (UUID) | ✅ | 다이어리 ID |

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "market_id": "123e4567-e89b-12d3-a456-426614174000",
  "content": "오늘 광장시장에서 맛있게 먹었어요!",
  "photo_ids": ["123e4567-e89b-12d3-a456-426614174000"],
  "keywords": ["대부분 현지인들이 방문해요", "한적해요"],
  "created_at": "2024-01-01T10:00:00Z"
}
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 다이어리를 찾을 수 없음
- `401 Unauthorized`: 인증 실패

#### Notes
- 본인이 작성한 다이어리만 조회 가능

---

### 4. 다이어리 수정

#### Endpoint
```
PUT /diary/{diary_id}
```

#### Description
다이어리 수정

#### Method
`PUT`

#### Request Headers
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| diary_id | string (UUID) | ✅ | 다이어리 ID |

#### Request Body
```json
{
  "market_id": "123e4567-e89b-12d3-a456-426614174000",
  "content": "수정된 내용",
  "photo_ids": ["123e4567-e89b-12d3-a456-426614174000"],
  "keywords": ["대부분 현지인들이 방문해요"]
}
```

#### Response Example
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "market_id": "123e4567-e89b-12d3-a456-426614174000",
  "content": "수정된 내용",
  "photo_ids": ["123e4567-e89b-12d3-a456-426614174000"],
  "keywords": ["대부분 현지인들이 방문해요"],
  "created_at": "2024-01-01T10:00:00Z"
}
```

#### Status Codes
- `200 OK`: 수정 성공
- `404 Not Found`: 다이어리를 찾을 수 없음
- `401 Unauthorized`: 인증 실패

---

### 5. 다이어리 삭제

#### Endpoint
```
DELETE /diary/{diary_id}
```

#### Description
다이어리 삭제

#### Method
`DELETE`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| diary_id | string (UUID) | ✅ | 다이어리 ID |

#### Response Example
```json
{
  "success": true,
  "message": "다이어리가 성공적으로 삭제되었습니다"
}
```

#### Status Codes
- `200 OK`: 삭제 성공
- `404 Not Found`: 다이어리를 찾을 수 없음
- `401 Unauthorized`: 인증 실패

---

### 6. 메뉴 좋아요

#### Endpoint
```
POST /diary/likes
```

#### Description
메뉴에 좋아요 추가

#### Method
`POST`

#### Request Headers
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

#### Request Body
```json
{
  "menu_item_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

#### Response Example
```json
{
  "success": true,
  "message": "좋아요가 추가되었습니다"
}
```

#### Status Codes
- `200 OK`: 좋아요 추가 성공
- `401 Unauthorized`: 인증 실패

#### Notes
- 이미 좋아요한 메뉴는 중복 추가되지 않음

---

### 7. 좋아요 취소

#### Endpoint
```
DELETE /diary/likes/{menu_item_id}
```

#### Description
메뉴 좋아요 취소

#### Method
`DELETE`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| menu_item_id | string (UUID) | ✅ | 메뉴 아이템 ID |

#### Response Example
```json
{
  "success": true,
  "message": "좋아요가 취소되었습니다"
}
```

#### Status Codes
- `200 OK`: 좋아요 취소 성공
- `404 Not Found`: 좋아요를 찾을 수 없음
- `401 Unauthorized`: 인증 실패

---

### 8. 핀 추가

#### Endpoint
```
POST /diary/pins
```

#### Description
가게 또는 메뉴에 핀 추가 (북마크)

#### Method
`POST`

#### Request Headers
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

#### Request Body
```json
{
  "shop_id": "123e4567-e89b-12d3-a456-426614174000",
  "menu_item_id": null
}
```

또는

```json
{
  "shop_id": null,
  "menu_item_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

#### Request Body Schema
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| shop_id | string (UUID) | ❌ | 가게 ID (shop_id 또는 menu_item_id 중 하나 필수) |
| menu_item_id | string (UUID) | ❌ | 메뉴 아이템 ID |

#### Response Example
```json
{
  "success": true,
  "message": "핀이 추가되었습니다"
}
```

#### Status Codes
- `200 OK`: 핀 추가 성공
- `400 Bad Request`: shop_id와 menu_item_id 모두 없음
- `401 Unauthorized`: 인증 실패

---

### 9. 내 좋아요 목록

#### Endpoint
```
GET /diary/my-likes
```

#### Description
현재 사용자가 좋아요한 메뉴 목록 조회

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| limit | integer | ❌ | 최대 반환 개수 (기본값: 20) |
| offset | integer | ❌ | 오프셋 (기본값: 0) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "떡볶이",
    "name_en": "Tteokbokki",
    "description": "쫄깃한 떡과 매콤한 양념",
    "rep_image_url": "https://example.com/tteokbokki.jpg",
    "category": "Meals",
    "spice_level": 3
  }
]
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

---

### 10. 내 핀 목록

#### Endpoint
```
GET /diary/my-pins
```

#### Description
현재 사용자가 핀한 가게/메뉴 목록 조회

#### Method
`GET`

#### Request Headers
```
Authorization: Bearer {access_token}
```

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| limit | integer | ❌ | 최대 반환 개수 (기본값: 20) |
| offset | integer | ❌ | 오프셋 (기본값: 0) |

#### Response Example
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "shop_id": "123e4567-e89b-12d3-a456-426614174000",
    "menu_item_id": null,
    "created_at": "2024-01-01T10:00:00Z"
  }
]
```

#### Status Codes
- `200 OK`: 성공
- `401 Unauthorized`: 인증 실패

---

## 지도 - 시장 (Market Photos)

### 1. 최근 사진 조회

#### Endpoint
```
GET /markets/{market_id}/recent-photos
```

#### Description
시장의 최근 사진 조회 (60분 이내, 카테고리 필터링 가능)

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ✅ | 시장 ID |

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| category | string | ❌ | 카테고리 필터 (Meals, Snacks, Sweets, Drink) |
| limit | integer | ❌ | 최대 반환 개수 (기본값: 10, 최대: 50) |

#### Response Example
```json
{
  "success": true,
  "photos": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "s3_key": "photos/20240101_100000_abc123.jpg",
      "thumbnail_s3_key": "thumbnails/20240101_100000_abc123_300x300.jpg",
      "image_url": "https://s3.amazonaws.com/bucket/photos/...",
      "thumbnail_url": "https://s3.amazonaws.com/bucket/thumbnails/...",
      "lat": 37.5665,
      "lng": 126.9780,
      "taken_at": "2024-01-01T10:00:00Z",
      "parsed_items": {
        "menu_name": "떡볶이",
        "bbox": [[10, 20, 100, 120]]
      },
      "created_at": "2024-01-01T10:00:05Z"
    }
  ],
  "total_count": 1
}
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 시장을 찾을 수 없음

#### Notes
- 60분 이내의 사진만 조회
- `processed = true`이고 `parsed_items`가 있는 사진만 반환
- S3 presigned URL은 응답에 포함됨

---

### 2. Bestselling 메뉴 조회

#### Endpoint
```
GET /markets/{market_id}/bestselling
```

#### Description
시장의 Bestselling 메뉴 조회 (좋아요 수 기준)

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ✅ | 시장 ID |

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| limit | integer | ❌ | 최대 반환 개수 (기본값: 3, 최대: 10) |

#### Response Example
```json
{
  "success": true,
  "bestselling": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "떡볶이",
      "name_en": "Tteokbokki",
      "name_zh": "炒年糕",
      "name_ja": "トッポッキ",
      "rep_image_url": "https://example.com/tteokbokki.jpg",
      "description": "쫄깃한 떡과 매콤한 양념",
      "like_count": 150
    }
  ]
}
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 시장을 찾을 수 없음

---

### 3. 가게 상태 조회

#### Endpoint
```
GET /markets/{market_id}/shops/status
```

#### Description
시장의 가게 목록과 영업 상태 조회 (녹색/황색/적색)

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ✅ | 시장 ID |

#### Response Example
```json
{
  "success": true,
  "shops": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "명동 떡볶이집",
      "name_en": "Myeongdong Tteokbokki",
      "name_zh": "明洞炒年糕店",
      "name_ja": "明洞トッポッキ店",
      "lat": 37.5665,
      "lng": 126.9780,
      "address": "서울특별시 중구 명동",
      "rep_image_url": "https://example.com/shop.jpg",
      "open_time": "09:00",
      "close_time": "22:00",
      "closed_days": [0, 6],
      "last_reported_open_at": "2024-01-01T10:00:00Z",
      "status": "green"
    }
  ],
  "total_count": 1
}
```

#### Response Schema
| 필드 | 타입 | 설명 |
|------|------|------|
| success | boolean | 성공 여부 |
| shops | array | 가게 목록 |
| shops[].status | string | 영업 상태 ("green", "yellow", "red") |
| total_count | integer | 전체 가게 수 |

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 시장을 찾을 수 없음

#### Notes
- 영업 상태 계산 로직:
  - **녹색**: 운영시간 내 + 제보/리뷰 존재
  - **황색**: 운영시간 경계 + 제보/리뷰 유무에 따라
  - **적색**: 그 외

---

### 4. 사진 위치 조회

#### Endpoint
```
GET /markets/{market_id}/photos/locations
```

#### Description
시장의 최근 사진 위치 조회 (지도 핀용, 60분 이내, 상위 N개)

#### Method
`GET`

#### Request Headers
없음 (인증 불필요)

#### Path Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| market_id | string (UUID) | ✅ | 시장 ID |

#### Query Parameters
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| limit | integer | ❌ | 최대 반환 개수 (기본값: 10, 최대: 20) |

#### Response Example
```json
{
  "success": true,
  "locations": [
    {
      "lat": 37.5665,
      "lng": 126.9780,
      "photo_id": "123e4567-e89b-12d3-a456-426614174000",
      "taken_at": "2024-01-01T10:00:00Z"
    }
  ]
}
```

#### Status Codes
- `200 OK`: 성공
- `404 Not Found`: 시장을 찾을 수 없음

#### Notes
- 60분 이내 사진만 조회
- 동일 위치는 하나로 그룹화 (약 10m 단위 반올림)
- 지도 핀 표시용

---

## 공통 응답 형식

### 성공 응답
```json
{
  "success": true,
  "message": "성공 메시지",
  "data": { ... }  // (선택적)
}
```

### 에러 응답
```json
{
  "success": false,
  "error_code": "ERROR_CODE",
  "message": "에러 메시지",
  "details": { ... }  // (선택적)
}
```

---

## 에러 코드

### HTTP 상태 코드

| 코드 | 설명 |
|------|------|
| 200 | OK - 요청 성공 |
| 400 | Bad Request - 잘못된 요청 |
| 401 | Unauthorized - 인증 실패 |
| 404 | Not Found - 리소스를 찾을 수 없음 |
| 500 | Internal Server Error - 서버 오류 |

### 커스텀 에러 코드

| 에러 코드 | HTTP 코드 | 설명 |
|----------|----------|------|
| AUTH_REQUIRED | 401 | 인증이 필요합니다 |
| TOKEN_EXPIRED | 401 | 토큰이 만료되었습니다 |
| RESOURCE_NOT_FOUND | 404 | 리소스를 찾을 수 없습니다 |
| VALIDATION_ERROR | 400 | 입력 값 검증 실패 |
| UPLOAD_FAILED | 500 | 업로드 실패 |
| PROCESSING_FAILED | 500 | 처리 실패 |

---

## 인증

대부분의 엔드포인트는 JWT Bearer Token을 사용한 인증을 필요로 합니다.

### 인증 헤더 형식
```
Authorization: Bearer {access_token}
```

### 토큰 획득
1. `POST /auth/google` 엔드포인트로 Google OAuth 인증
2. 응답에서 `access_token` 획득
3. 이후 모든 요청에 `Authorization` 헤더에 포함

### 토큰 만료
- 기본 만료 시간: 30분
- 만료 시 `POST /auth/refresh`로 토큰 갱신

---

## 페이지네이션

목록 조회 엔드포인트는 페이지네이션을 지원합니다.

### Query Parameters
- `limit`: 최대 반환 개수 (기본값: 엔드포인트별 상이)
- `offset`: 오프셋 (기본값: 0)

### 예시
```
GET /uploads/my-photos?limit=20&offset=0
GET /uploads/my-photos?limit=20&offset=20
```

---

## 타임스탬프 형식

모든 타임스탬프는 ISO 8601 형식을 사용합니다.

### 형식
```
YYYY-MM-DDTHH:mm:ssZ
```

### 예시
```
2024-01-01T10:00:00Z
```

---

## 파일 업로드

사진 업로드는 두 단계로 진행됩니다:

1. **업로드 초기화**: `POST /uploads/photo-init`로 presigned URL 획득
2. **S3 직접 업로드**: presigned URL로 S3에 직접 업로드
3. **업로드 완료 알림**: `POST /uploads/photo-complete`로 서버에 알림

### 예시 플로우

```javascript
// 1. 업로드 초기화
const initResponse = await fetch('/uploads/photo-init', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    lat: 37.5665,
    lng: 126.9780,
    taken_at: new Date().toISOString(),
    is_member: true
  })
});

const { presigned_url, s3_key, upload_token } = await initResponse.json();

// 2. S3에 직접 업로드
await fetch(presigned_url, {
  method: 'PUT',
  body: imageFile,
  headers: {
    'Content-Type': 'image/jpeg'
  }
});

// 3. 업로드 완료 알림
await fetch('/uploads/photo-complete', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    upload_token,
    s3_key,
    lat: 37.5665,
    lng: 126.9780,
    taken_at: new Date().toISOString(),
    photo_type: 'report'
  })
});
```

---

## 주의사항

1. **CORS**: 프론트엔드 도메인은 `.env`의 `ALLOWED_ORIGINS`에 설정되어야 함
2. **파일 크기**: 사진 업로드 시 파일 크기 제한 확인 필요 (S3 설정)
3. **Rate Limiting**: 과도한 요청 방지를 위한 Rate Limiting 고려
4. **에러 처리**: 모든 에러는 JSON 형식으로 반환됨

---

## 추가 리소스

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- Health Check: `http://localhost:8000/health`

---

*이 문서는 API v1.0.0 기준으로 작성되었습니다.*

