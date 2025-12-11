# Menu Matcher 설계 문서

## 개요

`MenuMatcherService`는 메뉴 매칭의 **단일 진실 소스 (Single Source of Truth)**입니다.

모든 메뉴 매칭은 이 서비스를 통해 수행되며, 다른 모델이나 로직은 참고용일 뿐입니다.

---

## 역할

### 1. 메뉴 매칭 (핵심 기능)

`MenuMatcherService.match_menu()`는 다음을 수행합니다:

1. **DB에서 모든 메뉴 목록 조회**
   - `menu_items` 테이블에서 모든 메뉴 이름을 가져옵니다.

2. **이미지와 텍스트를 사용하여 매칭**
   - OpenAI GPT-4V를 사용하여 이미지를 분석합니다.
   - 사용자 텍스트 설명(선택)을 함께 사용합니다.
   - DB menu_items 목록 중 하나를 선택합니다.

3. **최종 판단**
   - 매칭된 메뉴 이름이 DB menu_items에 존재하는지 확인합니다.
   - 존재하면 메뉴 이름을 반환하고, 없으면 None을 반환합니다.

### 2. 메뉴 목록 제공

`MenuMatcherService.get_all_menus()`는 DB에서 모든 메뉴 리스트를 반환합니다.

이 목록은 bbox 탐지 시 참고용으로 사용됩니다.

---

## 사용 시나리오

### 시나리오 1: Report/Review 사진 처리

```
원본 이미지 → bbox 탐지 → crop N개 생성
    ↓
각 crop에 대해:
    - menu_matcher.match_menu(image_url=crop_presigned_url)
    - 매칭 성공 시 저장, 실패 시 폐기
```

**특징:**
- crop된 이미지의 presigned URL을 사용합니다.
- 각 crop마다 독립적으로 매칭을 수행합니다.
- 매칭 실패 시 해당 crop은 폐기됩니다.

### 시나리오 2: Search 사진 처리

```
원본 이미지 (base64 또는 URL) → menu_matcher.match_menu()
    ↓
매칭 결과 반환 (저장 없음)
```

**특징:**
- 이미지를 저장하지 않고 메모리에서만 처리합니다.
- base64 인코딩된 이미지 또는 presigned URL을 사용합니다.
- 사용자 텍스트 설명(선택)을 함께 사용할 수 있습니다.

---

## API

### MenuMatcherService.match_menu()

```python
def match_menu(
    self, 
    image_url: Optional[str] = None, 
    image_base64: Optional[str] = None,
    user_text: Optional[str] = None
) -> Optional[str]:
    """
    GPT-4V를 이용하여 메뉴 추출
    
    Args:
        image_url: 이미지 URL (선택, image_base64와 함께 사용 불가)
        image_base64: base64 인코딩된 이미지 (선택, image_url과 함께 사용 불가)
        user_text: 사용자가 입력한 음식 묘사 (선택)
    
    Returns:
        메뉴 이름 혹은 None
    """
```

**입력:**
- `image_url`: presigned URL 또는 공개 URL
- `image_base64`: base64 인코딩된 이미지 (search 시나리오에서 사용)
- `user_text`: 사용자 텍스트 설명 (선택)

**출력:**
- 매칭된 메뉴 이름 (DB menu_items에 존재하는 경우)
- None (매칭 실패 또는 DB에 없는 경우)

**동작:**
1. DB에서 모든 메뉴 목록을 조회합니다.
2. OpenAI GPT-4V를 호출하여 이미지를 분석합니다.
3. 응답이 DB menu_items에 존재하는지 확인합니다.
4. 존재하면 메뉴 이름을 반환하고, 없으면 None을 반환합니다.

### MenuMatcherService.get_all_menus()

```python
def get_all_menus(self) -> List[str]:
    """
    DB에서 모든 메뉴 리스트 반환
    
    Returns:
        메뉴 이름 리스트
    """
```

**출력:**
- DB menu_items 테이블의 모든 메뉴 이름 리스트

**사용처:**
- bbox 탐지 시 참고용으로 사용됩니다.

---

## OpenAI Vision API 호출 형식

### 이미지 URL 사용

```python
response = self.openai_service.client.chat.completions.create(
    model="gpt-4o",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": image_url}}
        ]
    }],
    max_tokens=50,
    temperature=0.1
)
```

### Base64 이미지 사용

```python
image_data_url = f"data:image/jpeg;base64,{image_base64}"

response = self.openai_service.client.chat.completions.create(
    model="gpt-4o",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": image_data_url}}
        ]
    }],
    max_tokens=50,
    temperature=0.1
)
```

---

## Prompt 구조

### 기본 Prompt

```
다음 메뉴 중 하나만 선택하세요: [메뉴1, 메뉴2, ...]
사용자 설명: "사용자 입력 텍스트" (선택)
메뉴 이름 혹은 None 만 출력하세요.
```

### 특징

- DB menu_items 목록을 명시적으로 제공합니다.
- 사용자 텍스트 설명을 포함할 수 있습니다.
- 응답은 메뉴 이름 또는 None만 반환합니다.

---

## 예외 처리

1. **메뉴 목록이 비어있는 경우**
   - 경고 로그를 남기고 None을 반환합니다.

2. **OpenAI API 호출 실패**
   - 에러 로그를 남기고 None을 반환합니다.
   - 상세한 오류 정보를 로깅합니다.

3. **응답이 DB menu_items에 없는 경우**
   - None을 반환합니다 (매칭 실패로 처리).

---

## 로깅

모든 단계에서 상세한 로깅을 수행합니다:
- 메뉴 매칭 시작
- 사용된 입력 타입 (image_url, image_base64, text only)
- OpenAI 응답
- 메뉴 목록에 포함 여부
- 최종 결과

---

## 단일 진실 소스 원칙

### 다른 서비스와의 관계

1. **Vision Service**
   - bbox 탐지만 담당합니다.
   - 메뉴 매칭은 수행하지 않습니다.
   - candidates는 참고용일 뿐입니다.

2. **Photo Processing Service**
   - menu_matcher를 호출하여 메뉴 매칭을 수행합니다.
   - 직접 메뉴 매칭 로직을 구현하지 않습니다.

3. **Search API**
   - menu_matcher를 호출하여 메뉴 매칭을 수행합니다.
   - 저장하지 않고 결과만 반환합니다.

### 금지 사항

1. **다른 서비스에서 직접 메뉴 매칭을 수행하지 않습니다.**
   - 모든 메뉴 매칭은 menu_matcher를 통해 수행됩니다.

2. **Vision GPT 텍스트 기반 분류로 menu_items 매칭하지 않습니다.**
   - menu_matcher가 단일 진실 소스입니다.

3. **menu_matcher 외의 경로로 menu_items 존재 여부를 판정하지 않습니다.**
   - 모든 판정은 menu_matcher를 통해 수행됩니다.

---

## 확장성

### 향후 개선 가능한 부분

1. **Confidence Score 제공**
   - 현재는 매칭 성공/실패만 반환하지만, 신뢰도 점수를 추가할 수 있습니다.

2. **캐싱**
   - 자주 사용되는 메뉴 목록을 캐싱하여 성능을 개선할 수 있습니다.

3. **다중 매칭**
   - 여러 메뉴 후보를 반환하는 기능을 추가할 수 있습니다.

4. **Fallback 메커니즘**
   - presigned URL 실패 시 프록시 fallback을 추가할 수 있습니다.

