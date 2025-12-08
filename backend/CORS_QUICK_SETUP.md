# CORS 설정 빠른 가이드

## 문제
Flutter Web (`http://localhost:50000`)에서 FastAPI (`http://localhost:8000`)로 요청 시 CORS 오류 발생

## 해결 방법

### 방법 1: `.env` 파일에 추가 (권장)

`backend/.env` 파일에 다음 한 줄 추가:

```env
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:50000,http://127.0.0.1:50000
```

### 방법 2: 기본값 사용 (이미 설정됨)

`.env` 파일이 없거나 `ALLOWED_ORIGINS`를 설정하지 않은 경우, 기본값에 이미 포함되어 있습니다:
- ✅ `http://localhost:50000`
- ✅ `http://127.0.0.1:50000`

## 설정 적용

1. `.env` 파일 수정 (필요한 경우)
2. **백엔드 서버 재시작** (중요!)

```bash
# Docker Compose 사용 시
docker-compose restart backend

# 또는 직접 실행 시 서버 재시작
```

## 확인 방법

백엔드 서버 로그에서 다음 메시지 확인:
```
INFO: CORS 허용 오리진: ['http://localhost:3000', 'http://localhost:8080', 'http://localhost:50000', 'http://127.0.0.1:50000']
```

## 현재 CORS 설정 위치

**파일:** `backend/app/main.py` (28-35번 줄)

```python
# CORS 설정
allowed_origins = settings.get_allowed_origins_list()
logger.info(f"CORS 허용 오리진: {allowed_origins}")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,  # ✅ 인증 정보 허용
    allow_methods=["*"],     # ✅ 모든 메서드 허용
    allow_headers=["*"],     # ✅ 모든 헤더 허용
)
```

**설정 파일:** `backend/app/config.py`
- 기본값: `http://localhost:50000` 포함됨
- 환경 변수: `ALLOWED_ORIGINS` (`.env` 파일에서 읽음)

