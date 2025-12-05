# Flutter 웹앱 설정 가이드

## 사전 요구사항

- Flutter SDK 설치 (최신 안정 버전)
- Chrome 브라우저 (웹 테스트용)

## 초기 설정

### 1. 의존성 설치

```bash
cd frontend
flutter pub get
```

### 2. 환경 변수 설정

`.env.example` 파일을 참고하여 `.env` 파일을 생성하고 실제 값으로 채워주세요.

```bash
# Windows PowerShell
Copy-Item .env.example .env

# 또는 수동으로 .env 파일 생성
```

`.env` 파일 내용:
```env
API_BASE_URL=http://localhost:8000
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_REDIRECT_URI=http://localhost:8080/auth/callback
KAKAO_MAP_API_KEY=your-api-key
IMAGE_BASE_URL=http://localhost:9000/market-explorer-photos
```

### 3. 웹 실행

```bash
flutter run -d chrome
```

## 프로젝트 구조

```
frontend/
├── lib/
│   ├── main.dart                    # 앱 진입점
│   ├── config/                       # 설정
│   │   └── app_config.dart
│   ├── providers/                   # 상태 관리
│   │   └── auth_provider.dart
│   ├── services/                    # API 서비스
│   │   ├── api_service.dart
│   │   └── auth_service.dart
│   ├── models/                      # 데이터 모델
│   │   ├── enums.dart
│   │   ├── user_model.dart
│   │   ├── market_model.dart
│   │   ├── menu_model.dart
│   │   └── shop_model.dart
│   ├── screens/                     # 화면
│   │   ├── auth/                    # 인증
│   │   ├── onboarding/              # 온보딩
│   │   ├── report/                   # 가게 제보
│   │   ├── explore/                  # 탐색
│   │   ├── map/                      # 지도
│   │   ├── camera/                   # 카메라
│   │   └── my/                       # 마이페이지
│   ├── widgets/                      # 재사용 위젯
│   │   └── bottom_navigation_bar.dart
│   ├── router/                       # 라우팅
│   │   └── app_router.dart
│   └── utils/                        # 유틸리티
│       └── permissions.dart
├── web/                              # 웹 설정
│   └── index.html
├── pubspec.yaml                      # 의존성
├── .env.example                      # 환경 변수 예시
└── README.md
```

## 주요 기능

### 구현 완료
- ✅ 프로젝트 구조 설정
- ✅ 환경 변수 관리
- ✅ 상태 관리 (Provider)
- ✅ 라우팅 (go_router)
- ✅ API 서비스 레이어
- ✅ 인증 화면 (Welcome, Login)
- ✅ 온보딩 플로우 (언어 선택, 이름 입력, 이름 생성, 메인 1/2)
- ✅ 가게 제보 플로우 (가이드, 카메라, 가게 선택, 완료)
- ✅ 탐색 탭 (기본 구조)
- ✅ 지도 탭 (시장 선택, 시장 화면)
- ✅ 카메라 탭 (리뷰 사진 촬영)
- ✅ 마이 탭 (마이페이지)

### 향후 구현 필요
- API 연동 완성 (각 화면에서 실제 데이터 가져오기)
- 이미지 업로드 및 표시
- 지도 API 연동 (카카오맵/네이버맵)
- 검색 기능
- 다이어리 작성
- 핀한 가게 관리
- 저장한 메뉴 관리
- 설정 화면
- 프로필 수정

## 주의사항

1. **환경 변수**: `.env` 파일은 Git에 커밋하지 마세요 (`.gitignore`에 포함됨)
2. **Google OAuth**: 웹용 클라이언트 ID가 필요합니다
3. **지도 API**: 카카오맵 또는 네이버맵 API 키가 필요합니다
4. **백엔드 연동**: 백엔드 서버가 실행 중이어야 합니다

## 문제 해결

### 패키지 오류
```bash
flutter clean
flutter pub get
```

### 환경 변수 로드 실패
- `.env` 파일이 `frontend/` 루트에 있는지 확인
- 파일 내용이 올바른지 확인

### 웹 실행 오류
- Chrome이 설치되어 있는지 확인
- `flutter doctor`로 Flutter 환경 확인

