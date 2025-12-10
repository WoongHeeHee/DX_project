# 시장 탐방 서비스 - Flutter 웹앱

## 설정 방법

1. `.env.example` 파일을 복사하여 `.env` 파일 생성
   ```bash
   cp .env.example .env
   ```

2. `.env` 파일에 실제 API 키 및 설정 값 입력
   ```env
   # API 설정
   API_BASE_URL=http://localhost:8000
   API_TIMEOUT=30

   # Google OAuth (웹용)
   GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
   GOOGLE_REDIRECT_URI=http://localhost:8080/auth/callback

   # 지도 API (네이버맵)
   NAVER_MAP_CLIENT_ID=your-naver-map-client-id
   NAVER_MAP_CLIENT_SECRET=your-naver-map-client-secret

   # 환경
   ENVIRONMENT=development

   # 이미지 서버 (MinIO/S3)
   IMAGE_BASE_URL=http://localhost:9000/market-explorer-photos
   ```

3. 의존성 설치: `flutter pub get`

4. 웹 서버 실행: `flutter run -d chrome`

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── config/
│   └── app_config.dart       # 환경 변수 관리
├── providers/                # 상태 관리 (Provider)
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   └── ...
├── services/                 # API 서비스
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── ...
├── models/                   # 데이터 모델
├── screens/                   # 화면
│   ├── auth/
│   ├── onboarding/
│   ├── explore/
│   ├── map/
│   ├── camera/
│   └── my/
├── widgets/                  # 재사용 가능한 위젯
│   ├── navigation_bar.dart
│   └── ...
└── utils/                    # 유틸리티
    ├── permissions.dart
    └── ...
```

## 주요 기능

- Google OAuth 로그인
- 온보딩 플로우
- 가게 제보
- 시장 탐색 및 지도
- 메뉴 검색 및 추천
- 리뷰 작성 (다이어리)
- 핀한 가게 및 저장한 메뉴 관리
