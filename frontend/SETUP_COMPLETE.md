# Flutter 웹앱 설정 완료

## 완료된 작업

1. ✅ `.env` 파일 생성 완료
2. ✅ `pubspec.yaml`에 `.env` 파일을 assets에 추가
3. ✅ `flutter pub get` 실행 완료

## 다음 단계

### 1. 백엔드 서버 실행 확인

백엔드 서버가 실행 중인지 확인하세요:
```bash
cd ../backend
docker-compose up
```

또는 직접 실행:
```bash
cd ../backend
uvicorn app.main:app --reload
```

백엔드 서버는 `http://localhost:8000`에서 실행되어야 합니다.

### 2. 웹앱 실행

```bash
cd frontend
flutter run -d chrome
```

또는 특정 포트로 실행:
```bash
flutter run -d chrome --web-port=8080
```

### 3. 환경 변수 설정 (필요시)

`.env` 파일을 열어서 실제 API 키로 수정하세요:
- `GOOGLE_CLIENT_ID`: Google OAuth 클라이언트 ID
- `KAKAO_MAP_API_KEY`: 카카오맵 API 키 (선택사항)
- `NAVER_MAP_CLIENT_ID`: 네이버맵 클라이언트 ID (선택사항)

### 4. 문제 해결

#### 패키지 오류가 발생하는 경우:
```bash
flutter clean
flutter pub get
```

#### 환경 변수 로드 실패:
- `.env` 파일이 `frontend/` 루트에 있는지 확인
- `pubspec.yaml`의 `assets`에 `.env`가 포함되어 있는지 확인

#### 웹 실행 오류:
- Chrome이 설치되어 있는지 확인
- `flutter doctor`로 Flutter 환경 확인

## 현재 설정

- **API Base URL**: `http://localhost:8000`
- **이미지 서버**: `http://localhost:9000/market-explorer-photos`
- **환경**: `development`

## 참고사항

- `.env` 파일은 Git에 커밋되지 않습니다 (`.gitignore`에 포함됨)
- 실제 배포 시에는 프로덕션 환경 변수로 변경해야 합니다
- Google OAuth는 웹용 클라이언트 ID가 필요합니다

