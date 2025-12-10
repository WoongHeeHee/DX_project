# Frontend-Backend 연동 관련 확인 사항

## 1. Google OAuth 구현 방식

**현재 상황:**
- `login_screen.dart`에 Google 로그인 버튼이 있지만 실제 구현은 TODO 상태
- `FRONTEND_API_SPECIFICATION.md`에 따르면 `POST /auth/google`에 `code`와 `redirect_uri`를 보내야 함
- 하지만 `backend/app/api/auth.py`를 보면 `id_token`을 받도록 구현되어 있음

**확인 필요:**
- Flutter 웹에서 Google OAuth를 어떻게 구현할지?
  - 옵션 1: `google_sign_in` 패키지 사용 (웹 지원 확인 필요)
  - 옵션 2: 웹뷰를 통한 OAuth 플로우
  - 옵션 3: 직접 OAuth 2.0 플로우 구현
- 백엔드 API가 `id_token`을 받도록 되어 있는데, 프론트엔드에서 `code`를 받아서 `id_token`으로 변환해야 하는지, 아니면 직접 `id_token`을 받을 수 있는지?

## 2. 이미지 업로드 플로우

**현재 상황:**
- `FRONTEND_API_SPECIFICATION.md`에 따르면:
  1. `POST /uploads/photo-init` - presigned URL 받기
  2. S3에 직접 업로드
  3. `POST /uploads/photo-complete` - 업로드 완료 알림
  4. `POST /uploads/report-complete` - 가게 선택 후 제보 완료

**확인 필요:**
- S3 presigned URL로 직접 업로드할 때, Flutter 웹에서 어떻게 구현할지?
  - `dio`를 사용하여 PUT 요청으로 업로드?
  - 파일을 multipart/form-data로 변환해야 하는지?

## 3. 시장 목록 필터링

**현재 상황:**
- `explore_screen.dart`에서 지역별로 시장을 필터링하고 있음 (서울, 경기, 인천 등)
- 하지만 백엔드 API (`GET /markets`)에는 지역 필터 파라미터가 없음

**확인 필요:**
- 시장 목록을 가져온 후 프론트엔드에서 지역별로 필터링할지?
- 아니면 백엔드에 지역 필터 파라미터를 추가해야 하는지?
- 시장 데이터에 지역 정보가 포함되어 있는지?

## 4. 트렌드 배너 데이터

**현재 상황:**
- `explore_screen.dart`에서 국가/연령 필터에 따라 트렌드 배너를 표시
- `getTrendBanners()` 메서드가 더미 데이터를 반환
- 백엔드에 `GET /recommendations/nationality-age-trend` API가 있음

**확인 필요:**
- 트렌드 배너에 표시할 데이터를 어떤 API에서 가져올지?
  - `GET /recommendations/nationality-age-trend` 사용?
  - `GET /recommendations/trending` 사용?
  - 다른 API가 필요한지?

## 5. 카테고리별 메뉴 필터링

**현재 상황:**
- `explore_screen.dart`에서 "Korean Street Food" 섹션에 카테고리 탭이 있음 (Meals, Snacks, Sweets, Drink)
- `GET /menus` API에 `category` 파라미터가 있음

**확인 필요:**
- 카테고리 값이 정확히 일치하는지? (대소문자 구분 등)
- 백엔드에서 반환하는 카테고리 값과 프론트엔드에서 사용하는 값이 일치하는지?

## 6. 시장 최근 사진 조회

**현재 상황:**
- `FRONTEND_API_SPECIFICATION.md`에 `GET /markets/{market_id}/recent-photos` API가 있음
- `category` 파라미터로 필터링 가능

**확인 필요:**
- 이 API가 지도 화면에서 사용되는지?
- 사진의 `parsed_items` 필드 구조는 어떻게 되는지?

## 7. 가게 상태 표시

**현재 상황:**
- `GET /markets/{market_id}/shops/status` API가 있음
- `status` 값: "green", "yellow", "red"

**확인 필요:**
- 지도 화면에서 가게 상태를 어떻게 표시할지?
- 가게 목록 화면에서도 상태를 표시해야 하는지?

## 8. 다국어 처리

**현재 상황:**
- 모든 모델에 locale별 필드가 있음 (name, name_en, name_zh, name_ja 등)
- 사용자의 `locale` 설정에 따라 적절한 필드를 사용해야 함

**확인 필요:**
- 사용자의 locale은 어디서 가져올지?
  - 온보딩에서 설정한 값?
  - 앱 설정에서 변경 가능한지?
  - API 호출 시마다 `locale` 파라미터를 전달해야 하는지?

## 9. 에러 처리

**현재 상황:**
- `ApiService`에 기본적인 에러 처리가 구현되어 있음
- 401 에러 시 토큰 자동 제거

**확인 필요:**
- 401 에러 발생 시 로그인 화면으로 자동 이동해야 하는지?
- 네트워크 에러 발생 시 사용자에게 어떻게 알릴지?
- 각 화면에서 에러 처리를 어떻게 할지?

## 10. 로딩 상태 관리

**현재 상황:**
- API 호출 시 로딩 상태를 표시해야 함

**확인 필요:**
- 각 화면에서 로딩 인디케이터를 어떻게 표시할지?
- Provider나 다른 상태 관리 라이브러리를 사용할지?

## 11. 이미지 URL 처리

**현재 상황:**
- `IMAGE_BASE_URL` 환경 변수가 있음
- S3 URL이 직접 반환되는지, 아니면 상대 경로인지?

**확인 필요:**
- 이미지 URL이 절대 경로인지 상대 경로인지?
- 상대 경로라면 `IMAGE_BASE_URL`과 결합해야 하는지?

## 12. 페이지네이션

**현재 상황:**
- 여러 API에 `limit`과 `offset` 파라미터가 있음

**확인 필요:**
- 무한 스크롤을 구현할지, 아니면 페이지네이션 버튼을 사용할지?
- 각 화면에서 어떻게 페이지네이션을 처리할지?

---

## 답변 요약

### A1. Google OAuth
- 프론트엔드에서 id_token 받아서 바로 백엔드에 전달하는 방식으로 통일

### A2. 이미지 업로드
- Presigned URL을 사용하는 경우, Flutter Web에서는 dio를 이용하여 PUT 방식으로 binary bytes를 그대로 업로드
- multipart/form-data는 사용하지 않음

### A3. 시장 목록 필터링
- 프론트엔드에서 하드코딩으로 분류 (시장 추가 예정 없음)

### A4. 트렌드 배너
- 국가/연령 필터에 따른 트렌드 배너: `GET /recommendations/nationality-age-trend` 사용
- "당신 입맛에 딱 맞을거예요": 사용자가 좋아요를 누른 항목이 있으면 `get_personalized_recommendations()` 알고리즘, 없으면 전체 트렌드

### A5. 카테고리 필터링
- 정확히 일치함

### A6. 시장 최근 사진
- 지도 - 시장 화면 (1)의 바텀시트에 활용
- 사진의 parsed_items는 사용되지 않음

### A7. 가게 상태 표시
- 각 컨테이너 우측 상단에 점으로 표시
- 가게 목록 화면에서도 상태 표시

### A8. 다국어 처리
- 온보딩에서 설정한 값
- 앱 설정에서 변경 가능
- User Profile + Authorization Header에 locale 포함

### A9. 에러 처리
- 에러 발생 시 에러 발생 화면 노출
- 안내문구 (언어별 제공)과 "돌아가기" 버튼

### A10. 로딩 상태
- 화면에 어둡고 투명한 레이어 추가
- 로딩 중 상태를 심볼로 표시 (progress bar가 좌에서 우로)

### A11. 이미지 URL
- 절대 경로로 반환
- 백엔드에서 URL 조립 필요 시 추가

### A12. 페이지네이션
- 무한 스크롤 구현

