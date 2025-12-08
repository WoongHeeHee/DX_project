# FastAPI CORS 설정 가이드

## 문제 설명

Flutter Web (`http://localhost:50000`)에서 FastAPI 백엔드 (`http://localhost:8000`)로 요청을 보낼 때 CORS (Cross-Origin Resource Sharing) 오류가 발생하는 문제를 해결하기 위한 설정 가이드입니다.

### 발생하는 오류
```
DioExceptionType.connectionError (XHR onError)
CORS policy: No 'Access-Control-Allow-Origin' header is present
```

## 해결 방법

### 방법 1: `.env` 파일에 설정 추가 (권장)

`backend/.env` 파일을 생성하거나 수정하여 다음 내용을 추가하세요:

```env
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:50000,http://127.0.0.1:50000
```

**주의사항:**
- 쉼표로 여러 오리진을 구분합니다
- 포트 번호를 정확히 입력하세요
- 프로토콜(http/https)을 정확히 입력하세요
- 공백 없이 입력하세요

### 방법 2: 기본값 사용

`.env` 파일이 없거나 `ALLOWED_ORIGINS`를 설정하지 않은 경우, `config.py`의 기본값이 사용됩니다:
- `http://localhost:3000`
- `http://localhost:8080`
- `http://localhost:50000` ✅ (이미 추가됨)
- `http://127.0.0.1:50000` ✅ (이미 추가됨)

## 현재 CORS 설정 위치

CORS 설정은 `backend/app/main.py` 파일에 다음과 같이 설정되어 있습니다:

```python
# CORS 설정
allowed_origins = settings.get_allowed_origins_list()
logger.info(f"CORS 허용 오리진: {allowed_origins}")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,  # 인증 정보(쿠키, Authorization 헤더) 허용
    allow_methods=["*"],     # 모든 HTTP 메서드 허용
    allow_headers=["*"],     # 모든 헤더 허용
)
```

**설정 설명:**
- `allow_origins`: 허용할 오리진 목록
- `allow_credentials=True`: 인증 정보 전송 허용 (JWT 토큰 사용을 위해 필요)
- `allow_methods=["*"]`: 모든 HTTP 메서드 허용 (GET, POST, PUT, DELETE 등)
- `allow_headers=["*"]`: 모든 헤더 허용 (Authorization, Content-Type 등)

## 설정 확인 방법

### 1. `.env` 파일 확인

`backend/.env` 파일이 있는지 확인하고, 다음 내용이 포함되어 있는지 확인하세요:

```env
ALLOWED_ORIGINS=http://localhost:50000,http://127.0.0.1:50000
```

### 2. 백엔드 서버 로그 확인

백엔드 서버를 시작하면 다음과 같은 로그가 출력됩니다:

```
INFO: CORS 허용 오리진: ['http://localhost:3000', 'http://localhost:8080', 'http://localhost:50000', 'http://127.0.0.1:50000']
```

이 로그를 통해 현재 허용된 오리진 목록을 확인할 수 있습니다.

### 3. 브라우저 개발자 도구 확인

1. 브라우저 개발자 도구 열기 (F12)
2. Network 탭에서 실패한 요청 선택
3. Response Headers에서 다음 헤더 확인:
   - `Access-Control-Allow-Origin: http://localhost:50000`
   - `Access-Control-Allow-Credentials: true`
   - `Access-Control-Allow-Methods: *`
   - `Access-Control-Allow-Headers: *`

## 설정 적용 방법

### 1. `.env` 파일 생성/수정

`backend/` 디렉토리에 `.env` 파일을 생성하거나 수정합니다:

```bash
# Windows PowerShell
cd backend
notepad .env
```

또는 `env_example.txt`를 복사하여 `.env` 파일을 생성:

```bash
# Windows PowerShell
cd backend
Copy-Item env_example.txt .env
```

### 2. `.env` 파일에 추가할 내용

```env
# 기존 설정들...
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:50000,http://127.0.0.1:50000
```

### 3. 백엔드 서버 재시작

설정 변경 후 백엔드 서버를 재시작해야 합니다:

```bash
# Docker Compose 사용 시
docker-compose restart backend

# 또는 직접 실행 시
# 서버를 중지하고 다시 시작
```

## 문제 해결 체크리스트

다음 항목을 확인하세요:

- [ ] `backend/.env` 파일에 `ALLOWED_ORIGINS` 설정이 있음
- [ ] `ALLOWED_ORIGINS`에 `http://localhost:50000` 포함됨
- [ ] 포트 번호가 정확함 (50000)
- [ ] 프로토콜이 정확함 (http)
- [ ] 백엔드 서버가 재시작됨
- [ ] 백엔드 서버 로그에서 CORS 허용 오리진 확인됨

## 추가 오리진 추가 방법

다른 포트나 도메인을 추가하려면:

1. `.env` 파일에서 `ALLOWED_ORIGINS` 수정:
   ```env
   ALLOWED_ORIGINS=http://localhost:50000,http://localhost:50001,https://yourdomain.com
   ```

2. 또는 `config.py`의 기본값 수정:
   ```python
   ALLOWED_ORIGINS: str = Field(
       default="http://localhost:3000,http://localhost:8080,http://localhost:50000,http://yourdomain.com",
       ...
   )
   ```

3. 백엔드 서버 재시작

## 프로덕션 환경 설정

프로덕션 환경에서는 보안을 위해:

1. **특정 도메인만 허용:**
   ```env
   ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
   ```

2. **와일드카드 사용 금지:**
   ```python
   # ❌ 프로덕션에서는 사용하지 마세요
   allow_origins=["*"]
   
   # ✅ 특정 도메인만 명시
   allow_origins=["https://yourdomain.com"]
   ```

3. **HTTPS 사용:**
   - 프로덕션에서는 반드시 HTTPS를 사용하세요

## 참고 자료

- [FastAPI CORS 문서](https://fastapi.tiangolo.com/tutorial/cors/)
- [MDN CORS 문서](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

## 요약

✅ **`backend/.env` 파일에 `ALLOWED_ORIGINS` 추가**
```env
ALLOWED_ORIGINS=http://localhost:50000,http://127.0.0.1:50000
```

✅ **백엔드 서버 재시작**

✅ **서버 로그에서 CORS 설정 확인**

이제 Flutter Web에서 FastAPI 백엔드로 요청을 보낼 수 있습니다!

