# 🌐 Cloudflare Tunnel 배포 가이드 (상세 설명)

## ✅ 배포 가능 여부: **가능합니다!**

DEPLOYMENT.md에 있는 방식으로 진행하면 배포가 가능합니다. 다만 몇 가지 중요한 제약사항과 "서버"의 위치를 명확히 이해하셔야 합니다.

---

## 🖥️ "서버"는 어디에 있나요?

### **답: 여러분의 로컬 컴퓨터입니다!**

Cloudflare Tunnel 방식에서는 **별도의 클라우드 서버가 없습니다**. 대신:

1. **백엔드 서버**: 여러분의 컴퓨터에서 Docker로 실행
   - 위치: `localhost:8000` (여러분의 컴퓨터)
   - 실행 방법: `docker compose up` (backend 폴더에서)

2. **프론트엔드 서버**: 여러분의 컴퓨터에서 Flutter로 실행
   - 위치: `localhost:50000` (여러분의 컴퓨터)
   - 실행 방법: `flutter run -d chrome --web-hostname 0.0.0.0 --web-port 50000`

3. **Cloudflare Tunnel**: 여러분의 컴퓨터에서 실행되는 프로그램
   - 역할: 로컬 서버들을 인터넷에 노출
   - 실행 방법: `cloudflared tunnel run [tunnel-name]`

### 📊 전체 구조도

```
┌─────────────────────────────────────────────────────────┐
│         여러분의 로컬 컴퓨터 (Windows)                    │
│                                                          │
│  ┌──────────────┐      ┌──────────────┐                │
│  │  Docker      │      │  Flutter     │                │
│  │  Backend     │      │  Frontend    │                │
│  │  :8000       │      │  :50000      │                │
│  └──────┬───────┘      └──────┬───────┘                │
│         │                     │                         │
│         └──────────┬──────────┘                         │
│                    │                                    │
│         ┌──────────▼──────────┐                        │
│         │ Cloudflare Tunnel   │                        │
│         │ (cloudflared)       │                        │
│         └──────────┬───────────┘                        │
└────────────────────┼───────────────────────────────────┘
                     │
                     │ 인터넷
                     │
         ┌───────────▼───────────┐
         │   Cloudflare 네트워크  │
         │   (무료 SSL 제공)      │
         └───────────┬───────────┘
                     │
         ┌───────────▼───────────┐
         │   사용자들 (외부)      │
         │   https://yourdomain │
         └──────────────────────┘
```

---

## ⚠️ 이 방식의 제약사항

### 1. **컴퓨터가 항상 켜져 있어야 함**
- 서비스를 제공하려면 여러분의 컴퓨터가 24시간 켜져 있어야 합니다
- 컴퓨터를 끄거나 재부팅하면 서비스가 중단됩니다
- 절전 모드로 들어가면 서비스가 중단됩니다

### 2. **인터넷 연결이 필수**
- 인터넷이 끊기면 서비스가 중단됩니다
- 여러분의 인터넷 속도가 서비스 속도에 영향을 줍니다

### 3. **전력 소비**
- 컴퓨터를 24시간 켜두면 전기료가 발생합니다

### 4. **보안 고려사항**
- 로컬 컴퓨터가 인터넷에 노출됩니다
- 방화벽 설정이 중요합니다 (하지만 Cloudflare Tunnel이 일부 보호 제공)

### 5. **프로덕션 환경에는 부적합**
- 시연, 테스트, 소규모 사용에는 적합
- 실제 서비스 운영에는 권장하지 않음

---

## ✅ 진행 가능 여부 체크리스트

### 필수 요구사항

- [x] **Cloudflare 계정 및 도메인**: 이미 요청하셨다고 하셨으니 완료
- [ ] **Docker 설치**: Windows에 Docker Desktop 설치 필요
- [ ] **Flutter SDK 설치**: Flutter 웹 빌드 가능해야 함
- [ ] **Cloudflare Tunnel 설치**: `cloudflared` 프로그램 설치 필요
- [ ] **PostgreSQL 데이터베이스**: 외부 서버 또는 로컬 설치 필요
- [ ] **환경 변수 설정**: `.env` 파일에 모든 API 키 설정
- [ ] **Google OAuth 설정**: Google Cloud Console에서 리디렉션 URI 등록

### 기술적 요구사항

- [ ] **컴퓨터 사양**: 최소 8GB RAM, 4코어 CPU 권장
- [ ] **인터넷 속도**: 업로드 속도 최소 10Mbps 권장
- [ ] **방화벽**: Windows 방화벽에서 포트 8000, 50000 허용

---

## 📋 단계별 배포 가이드

### 1단계: 사전 준비

#### 1.1 Docker Desktop 설치
1. https://www.docker.com/products/docker-desktop/ 에서 다운로드
2. 설치 후 재부팅
3. Docker Desktop 실행 확인

#### 1.2 Flutter SDK 확인
```bash
flutter --version
flutter doctor
```

#### 1.3 Cloudflare Tunnel 설치
1. https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/ 참고
2. Windows용 다운로드 및 설치
3. 설치 확인: `cloudflared --version`

### 2단계: Cloudflare Tunnel 설정

#### 2.1 Tunnel 생성
Cloudflare 대시보드에서:
1. Zero Trust → Networks → Tunnels
2. "Create a tunnel" 클릭
3. Tunnel 이름 입력 (예: `market-explorer`)
4. "Save a credential file" 클릭하여 `.json` 파일 다운로드
5. 파일을 `C:\Users\[사용자명]\.cloudflared\` 폴더에 저장

#### 2.2 DNS 레코드 설정
Cloudflare 대시보드 → DNS에서:

**프론트엔드용:**
- Type: `CNAME`
- Name: `@` (또는 `www`)
- Target: `[Tunnel-UUID].cfargotunnel.com`
- Proxy status: Proxied (주황색 구름) ✅

**백엔드용:**
- Type: `CNAME`
- Name: `api`
- Target: `[Tunnel-UUID].cfargotunnel.com` (동일)
- Proxy status: Proxied (주황색 구름) ✅

#### 2.3 config.yml 파일 생성
`C:\Users\[사용자명]\.cloudflared\config.yml` 파일 생성:

```yaml
tunnel: [Tunnel-UUID]  # .json 파일 이름에서 확장자 제외
credentials-file: C:/Users/[사용자명]/.cloudflared/[Tunnel-UUID].json

ingress:
  # 프론트엔드 (메인 도메인)
  - hostname: yourdomain.com  # 실제 도메인으로 변경
    service: http://localhost:50000
  
  # 백엔드 (서브도메인)
  - hostname: api.yourdomain.com  # 실제 도메인으로 변경
    service: http://localhost:8000
  
  # 나머지는 404
  - service: http_status:404
```

**⚠️ 중요**: `yourdomain.com`을 실제 Cloudflare에서 받은 도메인으로 변경하세요!

### 3단계: 백엔드 설정

#### 3.1 환경 변수 파일 생성
`backend/.env` 파일 생성 (또는 `env_example.txt` 복사):

```env
# 데이터베이스 (외부 PostgreSQL 필요)
DATABASE_URL=postgresql://user:password@host:5432/market_explorer

# CORS 설정 (프론트엔드 도메인 추가)
ALLOWED_ORIGINS=http://localhost:50000,https://yourdomain.com

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# OpenAI
OPENAI_API_KEY=your-openai-api-key

# Pinecone
PINECONE_API_KEY=your-pinecone-api-key
PINECONE_ENVIRONMENT=us-west1-gcp
PINECONE_INDEX_NAME=market-explorer

# JWT
SECRET_KEY=your-very-secret-key-change-this

# 기타 설정은 env_example.txt 참고
```

#### 3.2 데이터베이스 준비
PostgreSQL이 필요합니다. 옵션:
- **옵션 A**: 외부 호스팅 서비스 사용 (Supabase, Railway, Neon 등)
- **옵션 B**: 로컬에 PostgreSQL 설치

#### 3.3 백엔드 실행
```bash
cd backend
docker compose up --build
```

정상 실행되면:
- 백엔드 API: http://localhost:8000
- API 문서: http://localhost:8000/docs

### 4단계: 프론트엔드 설정

#### 4.1 index.html 수정
`frontend/web/index.html` 파일에서:

```javascript
window.ENV = {
  API_BASE_URL: 'https://api.yourdomain.com',  // 실제 도메인으로 변경
  GOOGLE_CLIENT_ID: 'your-google-client-id'
};
```

#### 4.2 프론트엔드 실행
```bash
cd frontend
flutter run -d chrome --web-hostname 0.0.0.0 --web-port 50000 --profile
```

**⚠️ 중요**: 
- `--web-hostname 0.0.0.0`은 필수입니다 (외부 접속 허용)
- `--web-port 50000`은 config.yml과 일치해야 합니다

### 5단계: Google OAuth 설정

Google Cloud Console에서:

1. **Authorized JavaScript origins**에 추가:
   - `https://yourdomain.com`
   - `http://localhost:50000` (개발용)

2. **Authorized redirect URIs**에 추가:
   - `https://yourdomain.com/auth/callback`
   - `http://localhost:50000/auth/callback` (개발용)

### 6단계: Cloudflare Tunnel 실행

새 터미널/명령 프롬프트에서:

```bash
cloudflared tunnel run [tunnel-name]
```

또는 config.yml이 기본 위치에 있으면:

```bash
cloudflared tunnel run
```

정상 실행되면:
- "Connection established" 메시지 확인
- 에러가 없어야 함

### 7단계: 접속 확인

1. **프론트엔드**: `https://yourdomain.com` 접속
2. **백엔드 API**: `https://api.yourdomain.com/docs` 접속
3. **Health check**: `https://api.yourdomain.com/health` 접속

---

## 🔧 문제 해결

### 문제 1: Tunnel 연결 실패
**증상**: `cloudflared tunnel run` 실행 시 에러

**해결책**:
1. config.yml 파일 경로 확인
2. Tunnel UUID가 올바른지 확인
3. credentials-file 경로 확인 (Windows는 슬래시 사용)
4. Cloudflare 대시보드에서 Tunnel 상태 확인

### 문제 2: CORS 에러
**증상**: 브라우저 콘솔에 CORS 에러

**해결책**:
1. `backend/.env`의 `ALLOWED_ORIGINS`에 `https://yourdomain.com` 포함 확인
2. 백엔드 재시작: `docker compose restart api`

### 문제 3: Google 로그인 실패
**증상**: Google 로그인 시 에러

**해결책**:
1. Google Cloud Console의 redirect URI 확인
2. `https://yourdomain.com/auth/callback`이 정확히 등록되었는지 확인
3. `frontend/web/index.html`의 `GOOGLE_CLIENT_ID` 확인

### 문제 4: 프론트엔드가 백엔드에 연결 안 됨
**증상**: API 호출 실패

**해결책**:
1. `frontend/web/index.html`의 `API_BASE_URL`이 `https://api.yourdomain.com`인지 확인
2. 백엔드가 정상 실행 중인지 확인: `http://localhost:8000/health`
3. Tunnel이 정상 실행 중인지 확인

### 문제 5: 컴퓨터 재부팅 후 서비스 중단
**증상**: 재부팅 후 접속 불가

**해결책**:
1. Windows 시작 프로그램에 추가 (선택사항)
2. 또는 매번 수동으로 실행:
   - 백엔드: `docker compose up -d`
   - 프론트엔드: `flutter run ...`
   - Tunnel: `cloudflared tunnel run`

---

## 📊 실행 순서 요약

서비스를 시작할 때마다 다음 순서로 실행:

1. **백엔드 시작** (터미널 1)
   ```bash
   cd backend
   docker compose up
   ```

2. **프론트엔드 시작** (터미널 2)
   ```bash
   cd frontend
   flutter run -d chrome --web-hostname 0.0.0.0 --web-port 50000 --profile
   ```

3. **Tunnel 시작** (터미널 3)
   ```bash
   cloudflared tunnel run [tunnel-name]
   ```

**⚠️ 중요**: 세 개 모두 실행 중이어야 서비스가 작동합니다!

---

## 💡 자동 시작 설정 (선택사항)

### Windows 작업 스케줄러 사용

컴퓨터가 켜질 때 자동으로 실행되도록 설정할 수 있습니다:

1. **백엔드 자동 시작**:
   - 작업 스케줄러에서 새 작업 생성
   - 트리거: "컴퓨터 시작 시"
   - 작업: `docker compose up -d` (backend 폴더에서)

2. **Tunnel 자동 시작**:
   - 작업 스케줄러에서 새 작업 생성
   - 트리거: "컴퓨터 시작 시"
   - 작업: `cloudflared tunnel run [tunnel-name]`

**주의**: 프론트엔드는 Flutter 개발 서버이므로 자동 시작보다는 수동 실행 권장

---

## 🎯 최종 확인 체크리스트

배포 전 확인:

- [ ] Docker Desktop 실행 중
- [ ] PostgreSQL 데이터베이스 연결 가능
- [ ] `backend/.env` 파일에 모든 필수 설정 완료
- [ ] `frontend/web/index.html`의 `API_BASE_URL` 수정 완료
- [ ] Cloudflare DNS 레코드 설정 완료
- [ ] `config.yml` 파일 생성 및 설정 완료
- [ ] Google OAuth 리디렉션 URI 등록 완료
- [ ] 백엔드 실행 중 (`localhost:8000` 접속 가능)
- [ ] 프론트엔드 실행 중 (`localhost:50000` 접속 가능)
- [ ] Tunnel 실행 중 (에러 없음)
- [ ] `https://yourdomain.com` 접속 가능
- [ ] `https://api.yourdomain.com/docs` 접속 가능

---

## 📝 요약

### ✅ 가능한 것
- Cloudflare 무료 도메인으로 서비스 배포
- HTTPS 자동 제공 (Cloudflare)
- 공인 IP 없이도 인터넷 접속 가능
- 무료로 시작 가능

### ⚠️ 제약사항
- 여러분의 컴퓨터가 24시간 켜져 있어야 함
- 컴퓨터 재부팅 시 수동 재시작 필요
- 인터넷 연결 필수
- 프로덕션 환경에는 부적합

### 🎯 권장 사용 사례
- ✅ 시연회, 데모
- ✅ 소규모 테스트
- ✅ 개발 중 외부 접속 테스트
- ❌ 실제 서비스 운영 (장기)

---

## 🆘 도움이 필요하신가요?

각 단계에서 막히는 부분이 있으시면:
1. 에러 메시지를 확인하세요
2. 로그를 확인하세요 (Docker, Flutter, Tunnel)
3. 위의 "문제 해결" 섹션을 참고하세요

추가 질문이 있으시면 언제든지 물어보세요!

