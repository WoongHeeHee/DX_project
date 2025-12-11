# 프론트엔드-백엔드 API 연동 가이드

## 개요

이 문서는 프론트엔드(Flutter)가 백엔드 API를 호출하여 사진 업로드/검색 기능을 사용하는 방법을 설명합니다.

---

## API 엔드포인트 목록

### 1. Presigned URL 발급

**엔드포인트**: `POST /photos/presign`

**설명**: S3에 직접 업로드하기 위한 presigned URL을 발급받습니다.

**인증**: 선택적 (회원인 경우 Bearer 토큰)

**요청**:
```json
(요청 본문 없음)
```

**응답**:
```json
{
  "upload_url": "https://s3.amazonaws.com/bucket/photos/...?X-Amz-Signature=...",
  "file_url": "photos/20231212_123456_abc123.jpg"
}
```

**Flutter 예시**:
```dart
final photoService = ApiRepository().photoService;
final presignResponse = await photoService.presignPhotoUpload();

// presignResponse.uploadUrl: S3 업로드용 presigned URL
// presignResponse.fileUrl: 업로드 후 사용할 S3 키
```

---

### 2. 사진 업로드 완료 처리

**엔드포인트**: `POST /photos`

**설명**: S3에 업로드된 사진의 처리를 시작합니다.

**인증**: 선택적 (회원인 경우 Bearer 토큰)

**요청**:
```json
{
  "photo_url": "photos/20231212_123456_abc123.jpg",
  "lat": 37.512825,
  "lng": 126.8903192,
  "photo_type": "review"  // "review" | "report" | "search"
}
```

**응답 (review/report)**:
```json
{
  "success": true,
  "message": "2개의 사진이 저장되었습니다.",
  "photo_ids": ["photo-id-1", "photo-id-2"],
  "matched_menu": null
}
```

**응답 (search)**:
```json
{
  "success": true,
  "message": "메뉴 인식 완료",
  "photo_ids": null,
  "matched_menu": "김치찌개"
}
```

**Flutter 예시**:
```dart
// 1. Presigned URL 발급
final presignResponse = await photoService.presignPhotoUpload();

// 2. S3에 직접 업로드
await photoService.uploadPhotoToS3(
  presignedUrl: presignResponse.uploadUrl,
  imageBytes: imageBytes,
);

// 3. 업로드 완료 알림
final uploadResponse = await photoService.uploadPhoto(
  photoUrl: presignResponse.fileUrl,
  lat: position.latitude,
  lng: position.longitude,
  photoType: 'review', // 'review' | 'report' | 'search'
);

// uploadResponse.photoIds: 저장된 photo_id 리스트 (review/report만)
// uploadResponse.matchedMenu: 매칭된 메뉴 이름 (search만)
```

---

### 3. 이미지 검색 (저장 없음)

**엔드포인트**: `POST /search/image-upload`

**설명**: 이미지를 업로드하여 메뉴를 검색합니다. 사진은 저장하지 않습니다.

**인증**: 불필요

**요청**: `multipart/form-data`
- `image`: 이미지 파일
- `user_text`: 사용자 텍스트 설명 (선택)
- `lat`: 위도 (선택)
- `lng`: 경도 (선택)

**응답**:
```json
{
  "success": true,
  "results": [
    {
      "menu_item": {
        "id": "menu-id",
        "name": "김치찌개",
        ...
      },
      "shops_nearby": [
        {
          "id": "shop-id",
          "name": "맛있는 식당",
          "distance": 0.5,
          ...
        }
      ]
    }
  ],
  "message": "검색 완료"
}
```

**Flutter 예시**:
```dart
final searchService = ApiRepository().searchService;
final searchResults = await searchService.imageSearchUpload(
  imageBytes: imageBytes,
  userText: query.isEmpty ? null : query,
  lat: lat,
  lng: lng,
);
```

---

## 전체 플로우

### 시나리오 1: 회원 리뷰 사진 업로드

```
1. 사용자가 사진 촬영
   ↓
2. POST /photos/presign
   → { upload_url, file_url }
   ↓
3. PUT {upload_url} (S3에 직접 업로드)
   → 이미지 바이트 전송
   ↓
4. POST /photos
   → { photo_url: file_url, lat, lng, photo_type: 'review' }
   ↓
5. 백엔드 처리 (동기)
   → bbox 탐지 → crop → menu_matcher 매칭 → S3 저장 → DB 저장
   ↓
6. 응답
   → { success: true, photo_ids: [...], message: "..." }
```

### 시나리오 2: 비회원 가게 제보 사진 업로드

```
1. 사용자가 사진 촬영
   ↓
2. POST /photos/presign
   → { upload_url, file_url }
   ↓
3. PUT {upload_url} (S3에 직접 업로드)
   → 이미지 바이트 전송
   ↓
4. POST /photos
   → { photo_url: file_url, lat, lng, photo_type: 'report' }
   ↓
5. 백엔드 처리 (동기)
   → bbox 탐지 → crop → menu_matcher 매칭 → S3 저장 → DB 저장
   ↓
6. 응답
   → { success: true, photo_ids: [...], message: "..." }
```

### 시나리오 3: 회원 메뉴 검색

```
1. 사용자가 사진 선택
   ↓
2. POST /search/image-upload
   → multipart/form-data { image, user_text, lat, lng }
   ↓
3. 백엔드 처리 (동기)
   → menu_matcher 매칭 (저장 없음)
   ↓
4. 응답
   → { success: true, results: [...], message: "..." }
```

---

## 에러 처리

### 일반적인 에러 응답

```json
{
  "detail": "에러 메시지"
}
```

### HTTP 상태 코드

- `200 OK`: 성공
- `400 Bad Request`: 잘못된 요청 (예: 필수 파라미터 누락)
- `401 Unauthorized`: 인증 실패
- `500 Internal Server Error`: 서버 오류

### Flutter 에러 처리 예시

```dart
try {
  final presignResponse = await photoService.presignPhotoUpload();
  // 성공 처리
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // 인증 실패 처리
  } else if (e.response?.statusCode == 500) {
    // 서버 오류 처리
  }
} catch (e) {
  // 기타 오류 처리
}
```

---

## 필드명 매핑

### 백엔드 (snake_case) → 프론트엔드 (camelCase)

| 백엔드 | 프론트엔드 |
|--------|-----------|
| `upload_url` | `uploadUrl` |
| `file_url` | `fileUrl` |
| `photo_url` | `photoUrl` |
| `photo_type` | `photoType` |
| `photo_ids` | `photoIds` |
| `matched_menu` | `matchedMenu` |

**참고**: FastAPI는 자동으로 snake_case를 JSON으로 변환하므로, 프론트엔드에서 `fromJson` 시 snake_case 필드명을 사용해야 합니다.

---

## 주의사항

1. **Presigned URL TTL**: presigned URL은 1시간 동안 유효합니다. 업로드는 즉시 수행해야 합니다.

2. **S3 업로드 Content-Type**: S3 업로드 시 `Content-Type: image/jpeg` 헤더를 포함해야 합니다.

3. **동기 처리**: `POST /photos` 엔드포인트는 동기 처리로 즉시 결과를 반환합니다. 타임아웃을 충분히 설정하세요.

4. **검색 사진 저장 안 함**: `POST /search/image-upload`는 사진을 저장하지 않습니다. 메모리에서만 처리합니다.

5. **photo_type 구분**:
   - `review`: 회원 리뷰용 사진 (저장)
   - `report`: 비회원 가게 제보 사진 (저장)
   - `search`: 메뉴 검색용 사진 (저장 안 함, `/search/image-upload` 사용)

---

## 테스트 예시

### cURL 예시

```bash
# 1. Presigned URL 발급
curl -X POST "http://localhost:8000/photos/presign" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 2. S3에 직접 업로드
curl -X PUT "PRESIGNED_UPLOAD_URL" \
  -H "Content-Type: image/jpeg" \
  --data-binary @image.jpg

# 3. 업로드 완료 알림
curl -X POST "http://localhost:8000/photos" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "photo_url": "photos/20231212_123456_abc123.jpg",
    "lat": 37.512825,
    "lng": 126.8903192,
    "photo_type": "review"
  }'
```

---

## 프론트엔드 코드 예시 (완전한 예시)

```dart
// 회원 리뷰 사진 업로드
Future<void> uploadReviewPhoto(XFile image, Position position) async {
  try {
    final photoService = ApiRepository().photoService;
    
    // 1. 이미지 바이트 읽기
    final imageBytes = await image.readAsBytes();
    
    // 2. Presigned URL 발급
    final presignResponse = await photoService.presignPhotoUpload();
    
    // 3. S3에 직접 업로드
    await photoService.uploadPhotoToS3(
      presignedUrl: presignResponse.uploadUrl,
      imageBytes: imageBytes,
    );
    
    // 4. 업로드 완료 알림
    final uploadResponse = await photoService.uploadPhoto(
      photoUrl: presignResponse.fileUrl,
      lat: position.latitude,
      lng: position.longitude,
      photoType: 'review',
    );
    
    // 5. 결과 처리
    if (uploadResponse.success) {
      print('업로드 성공: ${uploadResponse.photoIds?.length}개의 사진 저장됨');
    } else {
      print('업로드 실패: ${uploadResponse.message}');
    }
  } catch (e) {
    print('에러: $e');
  }
}
```

---

## 추가 정보

- 백엔드 API 문서: `http://localhost:8000/docs` (Swagger UI)
- 백엔드 리팩토링 문서: `PHOTO_PIPELINE_REDESIGNED.md`
- Menu Matcher 설계: `MENU_MATCHER_DESIGN.md`

