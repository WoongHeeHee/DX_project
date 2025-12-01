# 🎯 다음 단계 작업 가이드

이 문서는 프로젝트 완성을 위해 필요한 작업들을 정리한 것입니다.

---

## 🔐 1. 환경 변수 설정 (.env 파일 완성)

### 위치
- `backend/.env` 파일 생성 (또는 `backend/env_example.txt`를 복사)

### 필수 환경 변수 설정

```env
# 환경 설정
ENVIRONMENT=development
DEBUG=true

# 데이터베이스 (Docker Compose 사용 시 자동 설정됨)
DATABASE_URL=postgresql://postgres:password@localhost:5432/market_explorer

# Redis (Docker Compose 사용 시 자동 설정됨)
REDIS_URL=redis://localhost:6379/0

# JWT 설정
SECRET_KEY=your-secret-key-change-in-production-랜덤문자열생성필요
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Google OAuth (필수) 🌟
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# AWS S3 / MinIO (Docker Compose 사용 시 자동 설정됨)
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin123
AWS_REGION=us-east-1
S3_BUCKET_NAME=market-explorer-photos
S3_ENDPOINT_URL=http://localhost:9000

# OpenAI (필수) 🌟
OPENAI_API_KEY=your-openai-api-key

# Pinecone (필수) 🌟
PINECONE_API_KEY=your-pinecone-api-key
PINECONE_ENVIRONMENT=us-west1-gcp
PINECONE_INDEX_NAME=market-explorer

# 지도 API (선택)
MAP_PROVIDER=kakao  # kakao | naver
KAKAO_API_KEY=your-kakao-api-key
# 또는
NAVER_CLIENT_ID=your-naver-client-id
NAVER_CLIENT_SECRET=your-naver-client-secret

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Celery (Docker Compose 사용 시 자동 설정됨)
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# 사진 보존 정책
PHOTO_RETENTION_DAYS=180

# 추천 시스템
RECOMMENDATION_FACTORS=32
RECOMMENDATION_ALPHA=0.1
```

### 🌟 필수 API 키 발급 가이드

#### 1. Google OAuth 설정
- [Google Cloud Console](https://console.cloud.google.com/)
- API 및 서비스 > 사용자 인증 정보
- OAuth 2.0 클라이언트 ID 생성
- 승인된 리디렉션 URI: `http://localhost:3000/callback` (프론트엔드 주소)

#### 2. OpenAI API 키
- [OpenAI Platform](https://platform.openai.com/)
- API Keys > Create new secret key

#### 3. Pinecone API 키
- [Pinecone Console](https://app.pinecone.io/)
- API Keys > Create API Key
- 인덱스 생성: `market-explorer` (차원 수는 추후 결정)

#### 4. 지도 API (선택)
- **Kakao**: [Kakao Developers](https://developers.kakao.com/)
- **Naver**: [Naver Developers](https://developers.naver.com/)

---

## 📐 2. Figma 페이지 내 엔드포인트 정리

### 작업 목표
Figma 디자인과 실제 API 엔드포인트를 매핑하여 프론트엔드 개발자가 쉽게 연동할 수 있도록 정리

### 작업 순서

#### Step 1: 화면별 API 엔드포인트 매핑
`backend/structure.md` 파일을 참고하여 각 화면에서 사용하는 API 엔드포인트 정리

**예시:**
```
📱 최초 화면
  - POST /auth/google (Google 로그인)
  - (가게 제보는 인증 불필요)

📱 온보딩 화면
  - POST /users/onboarding (온보딩 완료)
  - POST /users/generate-korean-name (한국 이름 생성)

📱 지도 - 시장 선택 화면
  - GET /markets/ (시장 목록)
  - GET /markets/{id}/shops/status (가게 상태 조회)

📱 지도 - 시장 화면 (1)
  - GET /markets/{id}/recent-photos (최근 사진)
  - GET /markets/{id}/bestselling (Bestselling 메뉴)
  
... (각 화면별로 정리)
```

#### Step 2: Figma에 API 명시
- 각 화면/프레임에 주석으로 API 엔드포인트 추가
- 요청/응답 예시 포함

#### Step 3: 데이터 플로우 다이어그램
- 화면 간 데이터 흐름을 시각화
- API 호출 순서 명시

---

## 📚 3. API 명세서 정리

### 작업 목표
프론트엔드 개발자와 협업을 위한 완전한 API 명세서 작성

### 생성할 문서

#### 3.1 OpenAPI/Swagger 문서 자동 생성 ✅
- 이미 생성됨: `http://localhost:8000/docs`
- 추가 작업: 커스터마이징 및 상세 설명 추가

#### 3.2 API 명세서 Markdown 문서 생성
`backend/API_DOCUMENTATION.md` 파일 생성

**포함할 내용:**

```markdown
# 시장 탐방 API 명세서

## 📋 목차
1. 인증
2. 사용자
3. 시장 & 가게
4. 사진 업로드
5. 검색
6. 추천
7. 다이어리
8. 지도 - 시장

---

## 1. 인증

### POST /auth/google
Google OAuth 인증

**요청:**
```json
{
  "code": "google_id_token",
  "redirect_uri": "http://localhost:3000/callback"
}
```

**응답:**
```json
{
  "access_token": "jwt_token",
  "token_type": "bearer",
  "expires_in": 1800
}
```

**사용 화면:**
- 최초 화면 (Google 로그인 버튼)

... (각 엔드포인트별로 정리)
```

#### 3.3 Postman Collection 업데이트
- `backend/api_test_collection.json` 업데이트
- 모든 엔드포인트 추가
- 테스트 예시 포함

---

## 🗄️ 4. 데이터베이스 초기화

### 작업 순서

#### Step 1: Docker Compose 실행
```bash
cd backend
docker-compose up -d
```

#### Step 2: 데이터베이스 마이그레이션
```bash
docker-compose exec api alembic upgrade head
```

#### Step 3: 시드 데이터 생성
```bash
docker-compose exec api python seed_data.py
```

#### Step 4: MinIO 버킷 생성 확인
- MinIO Console 접속: `http://localhost:9001`
- 로그인: `minioadmin` / `minioadmin123`
- 버킷 `market-explorer-photos` 생성 확인 (자동 생성됨)

---

## 🧪 5. API 테스트 및 검증

### 작업 순서

#### Step 1: 기본 API 테스트
1. Swagger UI 접속: `http://localhost:8000/docs`
2. 헬스체크: `GET /health`
3. 시장 목록: `GET /markets/`

#### Step 2: 인증 테스트
- 개발용 테스트 엔드포인트 사용 (필요시 추가)
- 또는 Google OAuth 실제 테스트

#### Step 3: 주요 기능 테스트
- 사진 업로드 플로우
- 이미지 검색
- 추천 시스템

---

## 🎨 6. Figma 디자인과 API 연동 문서화

### 작업 목표
디자이너와 개발자 간 협업을 위한 명확한 가이드 제공

### 생성할 문서

#### 6.1 화면별 API 매핑 문서
`backend/FIGMA_API_MAPPING.md`

```markdown
# Figma 화면과 API 엔드포인트 매핑

## 화면명: 최초 화면
**Figma 프레임:** `최초화면`

### 사용 API
1. POST /auth/google
   - 화면: Google 로그인 버튼 클릭 시
   - 응답 처리: JWT 토큰 저장

2. (가게 제보는 인증 불필요)

---

## 화면명: 온보딩 - 이름생성 대기화면
**Figma 프레임:** `온보딩_이름생성`

### 사용 API
1. POST /users/generate-korean-name
   - 화면: 이름 입력 후 "확인" 버튼 클릭
   - 요청: `{ "input_name": "사용자 입력 이름" }`
   - 응답: `{ "korean_name": "홍록기", "pronunciation": "Hong-Loggi" }`
   - 로딩 처리: API 호출 중 로딩 표시

... (각 화면별로 정리)
```

#### 6.2 데이터 플로우 다이어그램
- 사용자 여정별 API 호출 순서
- 화면 전환 시 필요한 데이터

---

## 📝 7. 추가 문서화

### 7.1 에러 처리 가이드
- 각 API의 에러 코드 및 메시지
- 클라이언트에서 처리 방법

### 7.2 개발 환경 설정 가이드
- 로컬 개발 환경 세팅
- Docker 사용법
- 데이터베이스 마이그레이션

### 7.3 배포 가이드 (향후)
- 프로덕션 환경 설정
- 환경 변수 관리
- 모니터링 설정

---

## ✅ 작업 체크리스트

### 우선순위 1 (필수)
- [ ] `.env` 파일 생성 및 API 키 발급
  - [ ] Google OAuth 설정
  - [ ] OpenAI API 키
  - [ ] Pinecone API 키
  - [ ] 지도 API 키 (선택)

### 우선순위 2 (중요)
- [ ] 데이터베이스 초기화 및 시드 데이터 생성
- [ ] API 기본 테스트 완료
- [ ] `backend/API_DOCUMENTATION.md` 작성

### 우선순위 3 (권장)
- [ ] Figma 화면별 API 매핑 문서 작성
- [ ] Postman Collection 업데이트
- [ ] 에러 처리 가이드 작성

---

## 📞 도움이 필요한 부분

다음 작업은 추가 협의가 필요할 수 있습니다:

1. **테스트 데이터 설계**
   - 시드 데이터에 포함할 실제 시장/가게 정보
   - 테스트 사용자 계정

2. **프론트엔드 연동 방식**
   - 인증 토큰 저장 방식 (LocalStorage, Cookie 등)
   - API 호출 에러 처리 방식

3. **이미지 업로드 플로우**
   - 프론트엔드에서 S3 직접 업로드 구현 방법
   - 업로드 진행 상태 표시

---

## 🚀 다음 단계

작업 완료 후:
1. 프론트엔드 개발자와 API 명세서 공유
2. Figma 디자인과 API 매핑 문서 공유
3. 협업을 위한 Slack/Notion 등 문서 공유

