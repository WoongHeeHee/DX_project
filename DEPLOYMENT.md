# 시연회 배포 가이드

이 문서는 Cloudflare Tunnel을 사용하여 시연회에서 외부 사용자들이 접속할 수 있도록 설정하는 방법을 설명합니다.

## 전제 조건

1. Cloudflare 계정 및 도메인 설정 완료
2. `api.dxteamapex.com` DNS 레코드 설정 완료
3. `dxteamapex.com` DNS 레코드 설정 필요 (프론트엔드용)
4. Cloudflare Tunnel 설치 및 인증 완료

## 1단계: Cloudflare DNS 설정

### 백엔드 도메인 (이미 완료)
- Type: CNAME
- Name: `api`
- Target: `[Tunnel-UUID].cfargotunnel.com`
- Proxy status: Proxied (주황색 구름)

### 프론트엔드 도메인 (추가 필요)
Cloudflare 대시보드 → DNS 메뉴에서:

- Type: CNAME
- Name: `@` (또는 `www`)
- Target: `[Tunnel-UUID].cfargotunnel.com` (백엔드와 동일한 값)
- Proxy status: Proxied (주황색 구름)

## 2단계: Cloudflare Tunnel 설정 파일 생성

### config.yml 파일 위치
Windows: `C:\Users\[사용자명]\.cloudflared\config.yml`

### config.yml 내용

```yaml
tunnel: [Tunnel-UUID]  # .json 파일 이름 (확장자 제외)
# Windows 경로는 슬래시(/) 또는 이중 역슬래시(\\) 사용 (단일 역슬래시는 YAML 이스케이프 문제 발생 가능)
credentials-file: C:/Users/[사용자명]/.cloudflared/[Tunnel-UUID].json
# 또는: credentials-file: C:\\Users\\[사용자명]\\.cloudflared\\[Tunnel-UUID].json

ingress:
  # 1. 프론트엔드 규칙 (사용자가 접속할 주소)
  - hostname: dxteamapex.com
    service: http://localhost:50000

  # 2. 백엔드 규칙 (로그인/API용 주소)
  - hostname: api.dxteamapex.com
    service: http://localhost:8000

  # 3. 나머지는 404 처리 (필수)
  - service: http_status:404
```

### Tunnel UUID 확인 방법
1. `C:\Users\[사용자명]\.cloudflared\` 폴더로 이동
2. `.json` 파일 이름 확인 (예: `abc123-def456-ghi789.json`)
3. 파일 이름에서 확장자 제외한 부분이 Tunnel UUID입니다.

## 3단계: 백엔드 CORS 설정

### 방법 1: .env 파일 사용 (권장)
`backend/.env` 파일에 다음 추가:

```env
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:50000,http://127.0.0.1:50000,https://dxteamapex.com
```

### 방법 2: 기본값 사용
`.env` 파일이 없으면 `backend/app/config.py`의 기본값이 자동으로 사용됩니다.
(이미 `https://dxteamapex.com`이 포함되어 있음)

## 4단계: 프론트엔드 API 설정 확인

`frontend/web/index.html` 파일의 `API_BASE_URL`이 다음으로 설정되어 있는지 확인:

```javascript
API_BASE_URL: 'https://api.dxteamapex.com',
```

✅ 이미 수정 완료되었습니다.

## 5단계: Google Cloud Console 설정

⚠️ **중요**: 현재 구현에서는 **프론트엔드가 Google OAuth 콜백을 받습니다**.

- Google이 `id_token`을 프론트엔드(`/auth/callback`)로 전달
- 프론트엔드가 `id_token`을 받아 백엔드(`/auth/google`)로 전송
- 백엔드가 토큰을 검증하고 JWT 토큰 반환

따라서 **프론트엔드 도메인**을 Google Console에 등록해야 합니다.

Google Cloud Console → API 및 서비스 → 사용자 인증 정보에서:

### Authorized JavaScript origins
- `https://dxteamapex.com` ✅ (프론트엔드 도메인)
- `http://localhost:50000` (로컬 개발용, 선택사항)

### Authorized redirect URIs
- `https://dxteamapex.com/auth/callback` ✅ (프론트엔드 콜백 경로)
- `http://localhost:50000/auth/callback` (로컬 개발용, 선택사항)

❌ **백엔드 도메인(`api.dxteamapex.com`)은 등록하지 마세요!** 프론트엔드가 콜백을 받습니다.

## 6단계: 시연회 당일 실행 순서

### 1. Backend 실행
```bash
cd backend
docker compose up --build
```

### 2. Frontend 실행
```bash
cd frontend
flutter run -d chrome --web-hostname 0.0.0.0 --web-port 50000 --profile
```

### 3. Cloudflare Tunnel 실행
```bash
cloudflared tunnel run demo-server
```

⚠️ **중요**: `--url` 옵션을 사용하지 마세요! config.yml 파일을 자동으로 읽습니다.

## 7단계: 접속 확인

### 프론트엔드 접속
- 외부 사용자: `https://dxteamapex.com`
- 로컬 개발: `http://localhost:50000`

### 백엔드 API 확인
- API 문서: `https://api.dxteamapex.com/docs`
- Health check: `https://api.dxteamapex.com/health`

## 문제 해결

### CORS 에러 발생 시
1. `backend/.env` 파일의 `ALLOWED_ORIGINS` 확인
2. 백엔드 서버 재시작: `docker compose restart api`

### Tunnel 연결 실패 시
1. `config.yml` 파일 경로 및 내용 확인
2. Tunnel UUID가 올바른지 확인
3. Cloudflare 대시보드에서 Tunnel 상태 확인

### Google 로그인 실패 시
1. Google Cloud Console의 redirect URI 확인
2. 브라우저 콘솔에서 실제 redirect URI 확인
3. `https://dxteamapex.com/auth/callback`이 승인되어 있는지 확인

## 시연 흐름도

```
외부 사용자 (휴대폰/노트북)
  ↓
https://dxteamapex.com (Cloudflare)
  ↓
Cloudflare Tunnel (config.yml)
  ↓
http://localhost:50000 (Flutter Frontend)
  ↓
로그인 버튼 클릭
  ↓
https://api.dxteamapex.com (Cloudflare)
  ↓
Cloudflare Tunnel (config.yml)
  ↓
http://localhost:8000 (Docker Backend)
  ↓
Google OAuth 처리
  ↓
https://dxteamapex.com/auth/callback
  ↓
로그인 완료! 🎉
```

## 체크리스트

시연 시작 전 확인:

- [ ] Docker: 8000번 포트로 실행 중
- [ ] Frontend: 50000번 포트로 실행 중
- [ ] Tunnel: `cloudflared tunnel run temp-server` 실행 중 (에러 없음)
- [ ] DNS: `dxteamapex.com`과 `api.dxteamapex.com` 모두 설정 완료
- [ ] CORS: `https://dxteamapex.com`이 `ALLOWED_ORIGINS`에 포함됨
- [ ] Google OAuth: `https://dxteamapex.com/auth/callback` 승인 완료
- [ ] API 설정: `frontend/web/index.html`의 `API_BASE_URL`이 `https://api.dxteamapex.com`

이 모든 항목이 체크되면 시연 준비 완료입니다! 🚀

