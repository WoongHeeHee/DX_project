# 사진 처리 파이프라인 재설계 문서

## 개요

이 문서는 report/review/search 3가지 사진 처리 시나리오의 통일된 아키텍처를 설명합니다.

## 핵심 원칙

1. **menu_matcher.py가 메뉴 매칭의 단일 진실 소스 (Single Source of Truth)**
   - 모든 메뉴 매칭은 `MenuMatcherService.match_menu()`를 통해 수행됩니다.
   - 다른 모델이나 로직은 참고용일 뿐이며, 최종 판단은 menu_matcher가 합니다.

2. **report/review와 search의 명확한 분리**
   - report/review: 원본 → bbox 탐지 → crop → menu_matcher 매칭 → 저장
   - search: 원본 → menu_matcher 매칭 → 결과만 반환 (저장 없음)

3. **bbox 탐지는 Vision Service, 메뉴 매칭은 Menu Matcher**
   - Vision Service는 bbox 탐지만 담당합니다.
   - Menu Matcher는 메뉴 매칭만 담당합니다.

---

## 1. 비회원 가게 제보 (photo_type='report')

### 처리 흐름

```
[1] presigned URL로 원본 사진 다운로드
    ↓
[2] detect_foods_with_bbox() → bbox 목록 획득
    ↓
[3] Python(Pillow)로 crop N개 생성
    ↓
[4] for each crop:
    - matched = menu_matcher.match(crop)  # 단일 진실 소스
    - if matched is None: continue (폐기)
    - presign → S3 업로드 → Photo DB 저장
    ↓
[5] 원본 사진 processed=True 업데이트 및 정리
```

### 상세 설명

1. **원본 사진 다운로드**
   - S3에서 원본 사진을 다운로드합니다.
   - presigned URL을 생성하여 Vision API에 전달합니다 (TTL 1시간, ResponseContentType 명시).

2. **bbox 탐지**
   - `VisionService.detect_foods_with_bbox()`를 호출합니다.
   - 여러 음식의 bounding box 좌표를 반환합니다 (0~1 정규화).
   - candidates는 참고용이며, 최종 매칭은 menu_matcher가 수행합니다.

3. **Crop 생성**
   - Python(Pillow)을 사용하여 실제 이미지 crop을 수행합니다.
   - 정규화된 좌표를 픽셀 좌표로 변환하여 crop합니다.

4. **메뉴 매칭 및 저장**
   - 각 crop 이미지에 대해 `MenuMatcherService.match_menu()`를 호출합니다.
   - 매칭 실패 시 crop 이미지를 폐기합니다.
   - 매칭 성공 시:
     - presigned URL 생성 (TTL 1시간)
     - S3에 crop 이미지 업로드
     - Photo 테이블에 레코드 저장
     - 가장 가까운 shop 찾기 및 저장

5. **원본 사진 정리**
   - 원본 사진은 삭제합니다 (crop 이미지만 저장).

### 반환값

```python
{
    "success": bool,
    "saved_count": int,
    "saved_photo_ids": List[str],
    "rejected": bool,
    "message": str
}
```

---

## 2. 회원 리뷰용 사진 (photo_type='review')

### 처리 흐름

비회원 가게 제보와 **동일한 로직**을 사용합니다.

```
[1] presigned URL로 원본 사진 다운로드
    ↓
[2] detect_foods_with_bbox() → bbox 목록 획득
    ↓
[3] Python(Pillow)로 crop N개 생성
    ↓
[4] for each crop:
    - matched = menu_matcher.match(crop)  # 단일 진실 소스
    - if matched is None: continue (폐기)
    - presign → S3 업로드 → Photo DB 저장
    ↓
[5] 원본 사진 processed=True 업데이트 및 정리
```

### 반환값

```python
{
    "success": bool,
    "saved_count": int,
    "saved_photo_ids": List[str],
    "rejected": bool,
    "message": str
}
```

---

## 3. 회원 메뉴 검색 (photo_type='search')

### 처리 흐름

```
[1] 이미지 URL 또는 base64 이미지 받기
    ↓
[2] menu_matcher.match_menu() 호출
    ↓
[3] 매칭 결과 반환 (저장 없음)
```

### 상세 설명

1. **이미지 입력**
   - multipart/form-data로 이미지 파일을 받거나, base64 인코딩된 이미지를 받습니다.
   - **저장하지 않습니다** (메모리에서만 처리).

2. **메뉴 매칭**
   - `MenuMatcherService.match_menu()`를 호출합니다.
   - 이미지와 사용자 텍스트(선택)를 사용하여 DB menu_items와 매칭합니다.

3. **결과 반환**
   - 매칭된 메뉴 이름을 반환합니다.
   - 매칭 실패 시 None을 반환합니다.
   - **이미지 데이터는 저장하지 않고 폐기합니다**.

### 반환값

```python
Optional[str]  # 매칭된 메뉴 이름 또는 None
```

---

## 서비스 레이어 구조

### services/photo_processing_service.py
- 전체 워크플로 조립
- `process_review_photo()`: 리뷰 사진 처리
- `process_report_photo()`: 제보 사진 처리 (리뷰와 동일)
- `process_search_photo()`: 검색 사진 처리 (저장 없음)

### services/vision_service.py
- bbox 탐지 전용
- `detect_foods_with_bbox()`: 여러 음식 탐지 및 bbox 반환
- 메뉴 매칭은 담당하지 않음

### services/menu_matcher_service.py
- 메뉴 매칭 전용 (핵심, 단일 진실 소스)
- `match_menu()`: 이미지와 텍스트를 사용하여 DB menu_items와 매칭
- `get_all_menus()`: DB에서 모든 메뉴 리스트 반환

### utils/image_utils.py
- crop 전용
- `crop_image_by_bbox()`: bbox 좌표를 사용하여 이미지 crop
- `validate_bbox()`: bbox 좌표 유효성 검증

### services/s3_service.py
- presigned URL 생성 및 S3 업로드
- `generate_presigned_download_url()`: 다운로드용 presigned URL 생성 (TTL 1시간, ResponseContentType 명시)
- `upload_file()`: 파일 업로드

### tasks/photo_tasks.py
- Celery 비동기 작업 (현재는 동기 처리로 변경됨)

### api/photos.py
- 외부 인터페이스
- `POST /photos/presign`: presigned URL 발급
- `POST /photos`: 사진 업로드 완료 처리

### api/search.py
- 검색 API
- `POST /search/image-upload`: 이미지 검색 (저장 없음)

---

## 제거된 기능

1. **check_is_food (음식 판별)**
   - 선택적 기능으로 제거되었습니다.
   - 필요 시 뒷단에서 menu_matcher가 최종 결정하므로 플로우를 방해하지 않습니다.

2. **vision_service.match_menu_from_crop()**
   - menu_matcher로 통일되었습니다.
   - Vision Service는 bbox 탐지만 담당합니다.

3. **중복 메뉴 매칭 로직**
   - menu_matcher 외의 메뉴 존재 판단 로직을 제거했습니다.

---

## presigned URL 생성 규칙

1. **생성 시점**: OpenAI Vision API 호출 직전에 생성
2. **TTL**: 3600초 (1시간) 고정
3. **ResponseContentType**: 명시적으로 설정 (예: "image/jpeg")
4. **검증**: 생성 후 HEAD 요청으로 검증

---

## 예외 처리

1. **원본 사진 다운로드 실패**: processed=True로 설정하고 종료
2. **bbox 탐지 실패**: processed=True로 설정하고 종료
3. **crop 실패**: 해당 crop 건너뛰기
4. **menu_matcher 매칭 실패**: 해당 crop 폐기
5. **S3 업로드 실패**: 해당 crop 건너뛰기
6. **DB 저장 실패**: 롤백 후 processed=True로 설정

---

## 로깅

모든 단계에서 상세한 로깅을 수행합니다:
- 처리 시작/완료
- 각 crop의 처리 결과
- 저장된 photo_ids
- 에러 발생 시 상세한 traceback

