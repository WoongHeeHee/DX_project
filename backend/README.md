# 🍜 시장 탐방 API 서버

방한 외국인을 위한 시장 탐방 모바일/웹 서비스의 백엔드 API 서버입니다.

## 🚀 주요 기능

- **🔐 사용자 인증**: Google OAuth 기반 인증 시스템
- **📸 사진 업로드**: S3 presigned URL을 통한 안전한 사진 업로드
- **🤖 AI 이미지 분석**: OpenAI GPT-4V를 활용한 음식 이미지 분석
- **🔍 벡터 검색**: Pinecone을 통한 유사 음식 검색
- **📍 위치 기반 서비스**: PostGIS를 활용한 반경 검색
- **💡 추천 시스템**: 협업 필터링 기반 개인화 추천
- **📱 다국어 지원**: 한국어, 영어, 중국어, 일본어

## 🏗️ 시스템 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Web Client    │    │   Admin Panel   │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │      FastAPI Server       │
                    │    (Load Balancer)        │
                    └─────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
    ┌─────┴─────┐         ┌─────┴─────┐         ┌─────┴─────┐
    │PostgreSQL │         │   Redis   │         │  Celery   │
    │ (PostGIS) │         │  (Cache)  │         │ (Workers) │
    └───────────┘         └───────────┘         └───────────┘
          │                      │                      │
    ┌─────┴─────┐         ┌─────┴─────┐         ┌─────┴─────┐
    │    S3     │         │ Pinecone  │         │  OpenAI   │
    │ (Photos)  │         │ (Vector)  │         │   API     │
    └───────────┘         └───────────┘         └───────────┘
```

## 📋 요구사항

- Python 3.11+
- PostgreSQL 15+ (PostGIS 확장)
- Redis 7+
- Docker & Docker Compose

## 🛠️ 로컬 개발 환경 설정

### 1. 저장소 클론

```bash
git clone <repository-url>
cd market-explorer-backend
```

### 2. 환경 변수 설정

```bash
cp env_example.txt .env
```

`.env` 파일을 편집하여 필요한 API 키들을 설정하세요:

```env
# 필수 설정
OPENAI_API_KEY=your-openai-api-key
PINECONE_API_KEY=your-pinecone-api-key
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# 지도 API (Kakao Maps - 프론트엔드에서 사용)
KAKAO_MAP_API_KEY=your-kakao-map-api-key
# 참고: Kakao Maps API 키는 프론트엔드 .env 파일에도 설정해야 합니다
```

### 3. Docker Compose로 서비스 시작

```bash
# 모든 서비스 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f api
```

### 4. 데이터베이스 마이그레이션

```bash
# 컨테이너 내에서 실행
docker-compose exec api alembic upgrade head
```

### 5. 시드 데이터 생성

```bash
# 컨테이너 내에서 실행
docker-compose exec api python seed_data.py
```

### 6. API 문서 확인

브라우저에서 다음 URL을 열어 API 문서를 확인하세요:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 🔧 개발 도구

### 로컬 Python 환경 (선택사항)

```bash
# 가상환경 생성
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 로컬 서버 실행
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 데이터베이스 마이그레이션

```bash
# 새 마이그레이션 생성
alembic revision --autogenerate -m "설명"

# 마이그레이션 적용
alembic upgrade head

# 마이그레이션 롤백
alembic downgrade -1
```

### Celery 작업 모니터링

```bash
# Celery 워커 로그 확인
docker-compose logs -f celery_worker

# Celery Beat 로그 확인
docker-compose logs -f celery_beat
```

## 📡 API 엔드포인트

### 인증
- `POST /auth/google` - Google OAuth 인증
- `GET /auth/me` - 현재 사용자 정보
- `POST /auth/refresh` - 토큰 갱신

### 사용자
- `GET /users/profile` - 프로필 조회
- `PUT /users/profile` - 프로필 수정
- `POST /users/onboarding` - 온보딩 완료

### 시장 & 가게
- `GET /markets` - 시장 목록
- `GET /markets/{id}` - 시장 상세 정보
- `POST /shops/nearby` - 근처 가게 검색
- `GET /shops/{id}` - 가게 상세 정보

### 사진 업로드
- `POST /uploads/photo-init` - 업로드 초기화
- `POST /uploads/photo-complete` - 업로드 완료
- `GET /uploads/my-photos` - 내 사진 목록

### 검색
- `POST /search/image` - 이미지 검색
- `GET /search/menu-items` - 메뉴 텍스트 검색
- `GET /search/popular-menus` - 인기 메뉴

### 추천
- `GET /recommendations` - 개인화 추천
- `GET /recommendations/trending` - 트렌딩 메뉴
- `POST /recommendations/feedback` - 추천 피드백

### 다이어리
- `POST /diary` - 다이어리 작성
- `GET /diary/my` - 내 다이어리 목록
- `POST /diary/likes` - 좋아요 추가
- `POST /diary/pins` - 핀 추가

## 🧪 테스트

### API 테스트 (cURL 예시)

```bash
# 헬스체크
curl http://localhost:8000/health

# 시장 목록 조회
curl http://localhost:8000/markets

# 근처 가게 검색
curl -X POST http://localhost:8000/shops/nearby \
  -H "Content-Type: application/json" \
  -d '{
    "lat": 37.5703,
    "lng": 126.9998,
    "radius_meters": 100
  }'
```

### 단위 테스트

```bash
# 테스트 실행
pytest

# 커버리지 포함
pytest --cov=app tests/
```

## 📊 모니터링 & 로깅

### 로그 확인

```bash
# 전체 서비스 로그
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f api
docker-compose logs -f celery_worker
```

### 데이터베이스 상태 확인

```bash
# PostgreSQL 접속
docker-compose exec postgres psql -U postgres -d market_explorer

# 테이블 확인
\dt

# 데이터 확인
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM photos;
```

### Redis 상태 확인

```bash
# Redis CLI 접속
docker-compose exec redis redis-cli

# 키 확인
KEYS *

# 통계 확인
INFO stats
```

## 🔄 배포

### 프로덕션 환경 변수

```env
ENVIRONMENT=production
DEBUG=false
DATABASE_URL=postgresql://user:pass@prod-db:5432/market_explorer
REDIS_URL=redis://prod-redis:6379/0
```

### Docker 이미지 빌드

```bash
# 이미지 빌드
docker build -t market-explorer-api .

# 이미지 실행
docker run -p 8000:8000 market-explorer-api
```

## 🤝 기여하기

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 있습니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🆘 문제 해결

### 자주 발생하는 문제

1. **PostgreSQL 연결 실패**
   ```bash
   # 컨테이너 재시작
   docker-compose restart postgres
   ```

2. **Celery 작업이 실행되지 않음**
   ```bash
   # Redis 연결 확인
   docker-compose exec redis redis-cli ping
   
   # Celery 워커 재시작
   docker-compose restart celery_worker
   ```

3. **OpenAI API 오류**
   - API 키가 올바른지 확인
   - API 사용량 한도 확인

4. **Pinecone 연결 오류**
   - API 키와 환경 설정 확인
   - 인덱스가 생성되었는지 확인

### 로그 레벨 조정

```env
# .env 파일에 추가
LOG_LEVEL=DEBUG
```

## 📞 지원

문제가 발생하거나 질문이 있으시면 다음을 통해 연락해 주세요:

- 이슈 트래커: [GitHub Issues](https://github.com/your-repo/issues)
- 이메일: support@market-explorer.com
- 문서: [API Documentation](https://api.market-explorer.com/docs)

---

**Happy Coding! 🚀**
