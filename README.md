# 시장 탐방 (DX Project)

LG DX School 부트캠프 최종 과제로 만든, **방한 외국인용 전통시장 탐방** 앱이다.

Flutter 웹 클라이언트와 FastAPI 백엔드로, 시장·메뉴를 탐색하고 사진으로 음식을 찾거나 제보할 수 있게 했다. 시연은 가상 **LG DX 시장**과 가상 메뉴 데이터로 진행했다.

---

## 배경 / 문제

부트캠프에서 LG전자와 맞닿는 아이템을 찾다 처음에는 해외 시장을 봤다. 방향을 「우리가 해외로 나가는 것」이 아니라 **한국에 오는 외국인**으로 바꾼 뒤, 전통시장에서 메뉴와 가게를 이해하기 어렵다는 문제에 맞춰 한국 문화를 소개하는 소프트웨어로 정리했다.

푸는 문제는 대략 다음이다.

- 한글 메뉴판·시장 동선을 모르는 방문객이 음식을 식별하기 어렵다.
- 「지금 이 골목에서 무엇이 보이는지」를 방문객이 서로 남기기 어렵다.
- 국적·연령 같은 맥락에 맞춰 메뉴를 고르기가 어렵다.

---

## 접근

로그인(Google)과 온보딩(언어, 한국 이름, 국적, 나이, 맵기, 한식 경험) 뒤에, 하단 탭으로 탐색 / 지도 / 카메라 / 마이를 제공한다. 로그인 전에도 가게 제보 흐름에 들어갈 수 있다.

검색과 제보 사진의 메뉴 식별은 임베딩 검색이 아니라, DB에 있는 메뉴 이름 목록을 **gpt-4o**에 주고 하나를 고르게 하는 방식이다. 위치는 PostGIS 없이 위경도 + Haversine이다.

원래 기획에는 Pinecone, PostGIS, ALS 협업필터, 네이버맵이 있었으나 일정 때문에 넣지 않았다. 코드와 설정에 흔적은 남아 있다.

---

## 구조 / 흐름

```text
Flutter (web)
  → FastAPI (:8000)
       ├── PostgreSQL
       ├── S3 (사진)
       └── OpenAI gpt-4o (이름 생성, bbox, 메뉴 매칭)

로컬 시연 시 Redis/Celery/MinIO도 docker-compose에 있다.
발표용 공개 URL은 Cloudflare Tunnel로 로컬 프로세스를 노출하는 문서가 있다.
```

활성 화면은 `frontend/lib/features/` 이다. `frontend/lib/router/app_router.dart`가 여기를 연결한다. `frontend/lib/screens/` 는 같은 도메인의 이전 화면이며 라우터에 연결되어 있지 않다.

### 사용자 흐름

1. Google 로그인 또는 가게 제보
2. 온보딩 → 지도(홈)
3. 탐색: 국적·연령 트렌드, 카테고리 메뉴, 시장 소개
4. 지도: 시장 선택 → Now 피드(최근 제보/리뷰 사진) / 가게 목록 / 저장
5. 검색: 사진 또는 텍스트로 메뉴 매칭
6. 카메라: 리뷰용 음식 사진
7. 마이: 프로필, 저장 가게·메뉴, 다이어리(일부 데모 화면 포함)

### 사진 처리 (제보 / 리뷰)

```text
촬영 → S3 presigned 업로드 → POST /photos
  → gpt-4o로 음식 bbox → Pillow crop
  → crop마다 gpt-4o가 DB 메뉴 중 하나 선택
  → 매칭된 crop만 저장, 원본 삭제
  → 근처 가게는 Haversine으로 연결
```

검색용 사진은 `POST /search/image-upload`에서 메모리만 쓰고 저장하지 않는다.

신규 `POST /photos`는 위 처리를 **동기**로 한다. 구 경로 `/uploads/photo-complete`는 Celery `delay`를 남기고 있다.

---

## 구현에서 중요한 부분

**메뉴 매칭.** `MenuMatcherService`가 검색과 사진 파이프라인의 단일 구현이다. 전체 메뉴명을 프롬프트에 넣고, 모델 출력이 목록에 있을 때만 히트로 본다.

**추천.** 라이브 API는 ALS를 쓰지 않는다. 같은 국적·연령대의 좋아요 집계, 또는 같은 메뉴를 좋아한 사람의 다른 메뉴다. 데이터가 없으면 하드코딩된 메뉴 ID 풀을 국적×연령으로 나눠 보여 준다.

**한국 이름.** 온보딩에서 `POST /users/generate-korean-name` → gpt-4o. (과거 분석 문서의 「더미 이름」은 현재 코드와 다르다.)

**지도 Now.** 시장 소속 가게의 처리 완료 사진을 `taken_at` 역순으로 준다. 기획 주석의 「60분 이내」필터는 이 엔드포인트에 없다.

**시연용 시장 데이터**

| 시장 | 데이터 |
|------|--------|
| LG DX 시장 | 발표에서 사용한 가상 시장·메뉴. 검색 결과의 「가까운 시장」도 여기로 고정 |
| 망원시장 | 실제 매장을 일부 넣었고, 메뉴는 임의 |
| 광장·통인 | UI 목록에 이름은 있으나 가게·메뉴 데이터 없음 |

메뉴 대표 이미지는 AI로 만들어 CloudFront에 올렸다.

---

## 기술 선택

| 문제 | 결정 | 이유 |
|------|------|------|
| 유사 음식 검색 | gpt-4o가 DB 메뉴 중 1개 선택 | Pinecone은 기획에 있었으나 시간 부족으로 제외 |
| 근처 가게 | lat/lng + Haversine | PostGIS도 같은 이유로 제외. 마이그레이션에 미사용이라고 적혀 있음 |
| 개인화 추천 | 좋아요 SQL 집계 + 고정 풀 fallback | ALS(`implicit`) 태스크는 남아 있으나 라이브 API는 사용하지 않음. 시간 부족으로 제외 |
| 지도 | Google Maps | 네이버맵 config는 있으나 시간 부족으로 제외 |
| 발표 배포 | 로컬 Docker/Flutter + Cloudflare Tunnel | 별도 앱 서버 구성은 저장소에 없음 |

---

## 결과

2025-12-15 커밋이 「최종발표회 버전」이다. 그 전(12-11)에 실시간 사진 노출이 동작한 기록이 있다.

발표 당일 아침에 OpenAI 매칭이 실패해, **메뉴 매칭과 실시간 사진 업로드는 시연하지 못했다.** 시연 무대는 가상 DX 시장이었다.

사용자 수, 매칭 정확도, 도메인 상시 가동 여부는 이 저장소로 확인할 수 없어 적지 않는다.

---

## 기여

팀 작업이다. Git 계정은 `WoongHeeHee` / `WoongHee Kim`(동일인)과 디자이너 `SurfingLouis`가 있다.

**김웅희**

- 백엔드, DB 스키마, API와 DB 연동
- 프론트↔백엔드 연결, 추천 등 내부 알고리즘
- 시연용 시장·메뉴 데이터 구성 (가상 DX 시장, 망원 일부 실매장)
- 기획은 팀과 분담 (본인 추산 일부)

**SurfingLouis**

- 화면 디자인 확정
- Dart 화면 구조·화면 로직

프론트의 시각/화면 골격은 디자이너가 넘긴 코드를 백엔드에 붙인 형태이다.

---

## 한계 / 남은 것

- OpenAI가 매칭·비전·이름 생성의 단일 장애점이다. 발표 당일 시연 실패가 그 예다.
- 메뉴 매칭은 목록 밖 음식이면 실패한다. 벡터 검색은 없다.
- 광장·통인은 이름만 있고 가게 데이터가 없다. 망원 메뉴는 실매장과 무관한 임의 값이다.
- `lib/screens/` 레거시, 미연결 `pinecone_service.py` / `image_processor_service.py`, 마운트되지 않은 `internal` 라우터, 앱과 무관한 프론트 카운터 테스트가 남아 있다.
- 마이의 쿠폰·선물 팝업 등은 데모 성격이다.
- 배포 문서상 서버는 발표자 PC다. 터널을 끄면 외부에서 닫힌다.
- `docker-compose.yml`에 클라우드 자격 증명이 하드코딩되어 있다. 값을 재사용하지 말고 교체해야 한다.
- 실행에는 OpenAI, Google OAuth, S3, Maps 키가 필요하다. 키 없이 이 저장소만으로는 전체 플로우를 재현할 수 없다.

---

## 기술 스택

| 기술 | 역할 |
|------|------|
| Flutter, go_router, provider, dio | 웹 클라이언트, 라우팅, 인증 상태, HTTP |
| Google Sign-In, Google Maps | 로그인, 지도 |
| FastAPI, SQLAlchemy, Alembic, PostgreSQL | API, ORM, 마이그레이션 |
| boto3 / S3, Pillow | 사진 업로드·crop |
| OpenAI gpt-4o | 메뉴 매칭, bbox, 한국 이름 |
| Redis, Celery | 브로커 및 구 사진 경로·배치 작업 (라이브 추천/신규 사진은 주로 동기 FastAPI) |
| Docker Compose | 로컬 API / Redis / MinIO / Celery |
| Cloudflare Tunnel | 로컬 시연을 HTTPS로 노출 (문서) |

라이브 경로에서 쓰지 않는 것: PostGIS, Pinecone, OpenCV, Sentry, 네이버맵 API, ALS 추천.

---

## 실행 방법

저장소에 있는 절차만 적는다. PostgreSQL은 compose에서 빠져 있고 `DATABASE_URL`로 외부 DB를 쓰도록 되어 있다.

### 백엔드

```bash
cd backend
cp env_example.txt .env   # OPENAI, Google, S3, DATABASE_URL 등 채움
docker compose up
# 또는
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

시작 시 Alembic upgrade를 시도한다. API 문서: `http://localhost:8000/docs`.

`env_example.txt`의 Pinecone·네이버 키는 현재 런타임이 요구하지 않는다.

### 프론트

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

프론트 README는 `API_BASE_URL=http://localhost:8000` 과 Google/Maps 키를 `.env`에 두라고 한다. 저장소에는 `.env.example` 파일이 보이지 않는다. 웹 시연 문서는 `flutter run -d chrome --web-hostname 0.0.0.0 --web-port 50000` 을 쓴다.

### 디렉터리

```text
backend/app/     FastAPI
frontend/lib/    Flutter (features/ 가 활성 UI)
structure.md     화면 기획
scripts/         S3 키 NFC 정규화
```

내부 재구성 기록은 `PROJECT_RECONSTRUCTION.md` 에 있다.
