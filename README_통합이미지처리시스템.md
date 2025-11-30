# 🍽️ 통합 이미지 처리 시스템

사용자가 업로드하는 3가지 이미지 케이스를 통합 처리하는 시스템입니다.

## 📋 시스템 개요

### 3가지 이미지 업로드 케이스

1. **🏪 비회원 가게 영업사진 업로드**
   - 가게 영업 상태 확인용
   - 음식 사진 vs 가게 사진 자동 분류
   - 55% 기준 음식 면적 판별

2. **🔍 회원 음식 검색**
   - 갤러리에서 업로드한 음식 사진 식별
   - 단일 메뉴 매칭
   - 사용자 프롬프트 지원

3. **📝 회원 음식 발자취(리뷰)**
   - 가게에서 촬영한 음식들 기록
   - 다중 이미지, 다중 메뉴 지원
   - 객체 탐지 및 바운딩 박스

## 🚀 빠른 시작

### 기본 사용법

```python
from api_handler import process_store_photo, search_food, record_food_trail

# 케이스 1: 가게 사진 처리
result = process_store_photo("https://example.com/store.jpg")

# 케이스 2: 음식 검색
result = search_food("https://example.com/food.jpg", "이게 뭔 음식인가요?")

# 케이스 3: 음식 발자취 기록
result = record_food_trail(["image1.jpg", "image2.jpg"], "store_123")
```

### 통합 API 사용법

```python
from api_handler import ImageAPIHandler

handler = ImageAPIHandler()

# 컨텍스트 기반 처리
context = {
    'type': 'store_photo',  # 'food_search', 'food_trail'
    'user_type': 'non_member',  # 'member'
    'store_id': 'store_123',  # food_trail용 (선택)
    'user_prompt': '설명'  # food_search용 (선택)
}

result = handler.handle_image_upload("image_url", context)
```

## 🏗️ 시스템 구조

### 핵심 컴포넌트

1. **`ImageProcessor`** (`src/image_processor.py`)
   - 이미지 분석 및 처리 로직
   - GPT-4V 기반 멀티모달 처리

2. **`ImageAPIHandler`** (`src/api_handler.py`)
   - 통합 API 인터페이스
   - 컨텍스트 기반 라우팅

3. **`menu_matcher`** (`src/menu_matcher.py`)
   - 메뉴 데이터베이스 관리
   - 기존 메뉴 매칭 로직

## 📊 처리 플로우

### 케이스 1: 비회원 가게 영업사진

```
이미지 입력 → 음식 분류 (55% 기준) → 분기 처리
├─ 음식 사진 (단일) → 메뉴 태깅
├─ 음식 사진 (다중) → 객체 탐지 + 다중 태깅
└─ 비음식 사진 → 가게 사진 적합성 판별
```

### 케이스 2: 회원 음식 검색

```
이미지 + 프롬프트 → GPT-4V 분석 → 메뉴 매칭 → 결과 반환
```

### 케이스 3: 회원 음식 발자취

```
다중 이미지 → 각각 음식 분류 → 단일/다중 처리 → 통합 결과
```

## 🔧 주요 기능

### 음식 분류 (`classify_food_image`)
- 음식 면적 55% 기준 판별
- 음식 개수 카운팅
- JSON 형태 결과 반환

### 다중 음식 탐지 (`detect_multiple_foods`)
- 바운딩 박스 좌표 생성
- 각 음식별 메뉴 분류
- 신뢰도 점수 제공

### 가게 사진 검증 (`validate_store_photo`)
- 부적합 사진 필터링
- 얼굴, 바닥, 흔들림 등 감지

## 📈 응답 형식

### 성공 응답
```json
{
    "success": true,
    "data": {
        "type": "single_food|multiple_foods|store_photo|food_search|food_trail",
        "menu": "메뉴명",
        "foods": [...],
        "classification": {...}
    },
    "context": {
        "user_type": "member|non_member",
        "purpose": "설명"
    }
}
```

### 오류 응답
```json
{
    "success": false,
    "error": "오류 메시지"
}
```

## 🧪 테스트

노트북에서 테스트 실행:
```bash
jupyter notebook notebooks/dev.ipynb
```

각 케이스별 테스트 코드가 포함되어 있습니다.

## ⚙️ 설정

### 환경 변수
```bash
OPENAI_API_KEY=your_api_key_here
```

### 의존성
```bash
pip install openai python-dotenv
```

## 🎯 최적화 고려사항

1. **성능 최적화**
   - 이미지 크기 제한
   - 배치 처리 지원
   - 캐싱 메커니즘

2. **비용 관리**
   - GPT-4V API 호출 최적화
   - 결과 캐싱
   - 실패 재시도 로직

3. **확장성**
   - 새로운 메뉴 추가 지원
   - 다국어 지원 준비
   - 커스텀 모델 통합 가능

## 📝 사용 예시

### 실제 사용 시나리오

```python
# 시나리오 1: 비회원이 가게 사진 업로드
result = process_store_photo("https://example.com/bibimbap.jpg")
if result['data']['type'] == 'single_food':
    print(f"영업중! 메뉴: {result['data']['menu']}")

# 시나리오 2: 회원이 음식 검색
result = search_food("https://example.com/unknown_food.jpg", "이게 뭔가요?")
if result['success']:
    print(f"이 음식은 {result['data']['menu']}입니다!")

# 시나리오 3: 회원이 음식 발자취 기록
images = ["meal1.jpg", "meal2.jpg", "meal3.jpg"]
result = record_food_trail(images, "dongdaemun_market_store_42")
print(f"총 {result['data']['total_menu_count']}개 메뉴 기록됨")
```

## 🔄 업데이트 로그

- **v1.0.0**: 초기 통합 시스템 구현
- 3가지 케이스 통합 처리
- GPT-4V 기반 멀티모달 분석
- 메뉴 데이터베이스 연동

---

**개발팀**: AI 이미지 처리팀  
**문의**: 프로젝트 관리자
