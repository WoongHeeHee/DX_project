# 환경 변수 설정 예시

`.env` 파일을 생성하고 아래 내용을 복사하여 실제 값으로 수정하세요.

```env
# API 설정
API_BASE_URL=http://localhost:8000
API_TIMEOUT=30

# Google OAuth (웹용)
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_REDIRECT_URI=http://localhost:8080/auth/callback

# 지도 API (카카오맵 또는 네이버맵)
KAKAO_MAP_API_KEY=your-kakao-map-api-key
NAVER_MAP_CLIENT_ID=your-naver-map-client-id
NAVER_MAP_CLIENT_SECRET=your-naver-map-client-secret

# 환경
ENVIRONMENT=development

# 이미지 서버 (MinIO/S3)
IMAGE_BASE_URL=http://localhost:9000/market-explorer-photos
```

## 각 항목 설명

- **API_BASE_URL**: 백엔드 API 서버 주소
- **API_TIMEOUT**: API 요청 타임아웃 (초)
- **GOOGLE_CLIENT_ID**: Google OAuth 클라이언트 ID (웹용)
- **GOOGLE_REDIRECT_URI**: Google OAuth 리디렉션 URI
- **KAKAO_MAP_API_KEY**: 카카오맵 API 키 (선택사항)
- **NAVER_MAP_CLIENT_ID**: 네이버맵 클라이언트 ID (선택사항)
- **NAVER_MAP_CLIENT_SECRET**: 네이버맵 클라이언트 시크릿 (선택사항)
- **ENVIRONMENT**: 환경 설정 (development/production)
- **IMAGE_BASE_URL**: 이미지 서버 기본 URL (MinIO 또는 S3)

