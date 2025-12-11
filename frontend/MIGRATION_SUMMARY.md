# 프론트엔드 API 마이그레이션 완료 보고서

## 📌 마이그레이션 개요

프론트엔드를 새로운 API 스펙(`/photos/presign`, `/photos`)으로 마이그레이션했습니다.

## ✅ 변경된 파일

### 1. `frontend/lib/data/models/photo_models.dart`

**추가된 모델**:
- `PhotoPresignResponse`: 새 API의 presigned URL 발급 응답
- `PhotoUploadResponse`: 새 API의 업로드 완료 응답

**유지된 모델** (하위 호환성):
- `PhotoUploadInitResponse`: 기존 API용 (deprecated)

### 2. `frontend/lib/data/services/photo_service.dart`

**새로운 메서드**:
- `presignPhotoUpload()`: `POST /photos/presign` 호출
- `uploadPhoto()`: `POST /photos` 호출

**Deprecated 메서드** (하위 호환성 유지):
- `initPhotoUpload()`: 기존 API 사용
- `completePhotoUpload()`: 기존 API 사용

### 3. `frontend/lib/screens/report/report_camera_screen.dart`

**변경사항**:
- 기존: `initPhotoUpload()` → `uploadPhotoToS3()` → `completePhotoUpload()`
- 신규: `presignPhotoUpload()` → `uploadPhotoToS3()` → `uploadPhoto()`

### 4. `frontend/lib/features/camera/camera_take_photo_screen.dart`

**변경사항**:
- 기존: `initPhotoUpload()` → `uploadPhotoToS3()` → `completePhotoUpload()`
- 신규: `presignPhotoUpload()` → `uploadPhotoToS3()` → `uploadPhoto()`

### 5. `frontend/lib/features/report/report_camera_screen.dart`

**변경사항**:
- 기존: `initPhotoUpload()` → `uploadPhotoToS3()` → `completePhotoUpload()`
- 신규: `presignPhotoUpload()` → `uploadPhotoToS3()` → `uploadPhoto()`

## 📌 API 스펙 변경 사항

### 기존 API (하위 호환성 유지)

```
1. POST /uploads/photo-init
   → { presigned_url, s3_key, upload_token }

2. PUT {presigned_url} (S3 직접 업로드)

3. POST /uploads/photo-complete
   → { upload_token, s3_key, lat, lng, taken_at, photo_type }
```

### 새 API (현재 사용)

```
1. POST /photos/presign
   → { upload_url, file_url }

2. PUT {upload_url} (S3 직접 업로드)

3. POST /photos
   → { photo_url, lat, lng, photo_type }
   → { success, message, photo_ids?, matched_menu? }
```

## 📌 주요 변경 사항

### 1. upload_token 제거

**기존**:
- `upload_token`을 받아서 `completePhotoUpload()`에 전달

**신규**:
- `upload_token` 불필요
- `file_url` (S3 키)만 전달

### 2. taken_at 제거

**기존**:
- `taken_at`을 클라이언트에서 전달

**신규**:
- `taken_at` 제거 (백엔드에서 자동 처리)

### 3. 응답 구조 변경

**기존**:
- `completePhotoUpload()`는 void 반환

**신규**:
- `uploadPhoto()`는 `PhotoUploadResponse` 반환
- `photo_ids` (review/report) 또는 `matched_menu` (search) 포함

## 📌 사용 예시

### 비회원 가게 제보 (report)

```dart
// 1. Presigned URL 발급
final presignResponse = await photoService.presignPhotoUpload();

// 2. S3에 직접 업로드
await photoService.uploadPhotoToS3(
  presignedUrl: presignResponse.uploadUrl,
  imageBytes: imageBytes,
);

// 3. 업로드 완료 알림
await photoService.uploadPhoto(
  photoUrl: presignResponse.fileUrl,
  lat: position.latitude,
  lng: position.longitude,
  photoType: 'report',
);
```

### 회원 리뷰 (review)

```dart
// 1. Presigned URL 발급
final presignResponse = await photoService.presignPhotoUpload();

// 2. S3에 직접 업로드
await photoService.uploadPhotoToS3(
  presignedUrl: presignResponse.uploadUrl,
  imageBytes: imageBytes,
);

// 3. 업로드 완료 알림
final response = await photoService.uploadPhoto(
  photoUrl: presignResponse.fileUrl,
  lat: position.latitude,
  lng: position.longitude,
  photoType: 'review',
);

// response.photoIds로 저장된 사진 ID 확인 가능
```

### 회원 메뉴 검색 (search)

```dart
// 1. Presigned URL 발급
final presignResponse = await photoService.presignPhotoUpload();

// 2. S3에 직접 업로드
await photoService.uploadPhotoToS3(
  presignedUrl: presignResponse.uploadUrl,
  imageBytes: imageBytes,
);

// 3. 업로드 완료 알림 (저장 없이 즉시 반환)
final response = await photoService.uploadPhoto(
  photoUrl: presignResponse.fileUrl,
  lat: position.latitude,
  lng: position.longitude,
  photoType: 'search',
);

// response.matchedMenu로 매칭된 메뉴 확인
if (response.matchedMenu != null) {
  print('매칭된 메뉴: ${response.matchedMenu}');
}
```

## 📌 하위 호환성

기존 API (`/uploads/photo-init`, `/uploads/photo-complete`)는 백엔드에서 계속 지원되며, 프론트엔드에서도 `@Deprecated` 메서드로 유지됩니다.

## ✅ 검증 완료

- [x] 모든 사진 업로드 화면 마이그레이션 완료
- [x] Linter 오류 없음
- [x] 하위 호환성 유지
- [x] 새 API 스펙 정확히 반영

## 📌 다음 단계

1. **테스트**: 실제 업로드 플로우 테스트
2. **모니터링**: 새 API 사용률 확인
3. **기존 API 제거** (선택): 모든 클라이언트가 새 API로 마이그레이션 완료 후 기존 API 제거 고려

