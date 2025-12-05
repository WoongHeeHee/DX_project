# Backend 폴더 마이그레이션 분석 결과

## 📋 분석 요약

**결론: backend/ 폴더로 이동해야 할 파일/폴더는 없습니다.**

backend/ 폴더는 이미 완전히 독립적으로 구성되어 있으며, 외부 파일(src/, notebooks/, 루트 파일)을 import하거나 참조하지 않습니다.

---

## ✅ Backend/ 폴더 현황

### 이미 Backend/ 내부에 있는 파일들
- ✅ `backend/structure.md` - 서비스 구조 문서
- ✅ `backend/requirements.txt` - Python 의존성 (독립적)
- ✅ `backend/README.md` - Backend 실행 가이드
- ✅ `backend/SYSTEM_ARCHITECTURE.md` - 시스템 아키텍처 문서
- ✅ 모든 서비스 코드 (`backend/app/`)

### Backend가 사용하지 않는 외부 파일
- ❌ `src/` 폴더 전체 - 모든 기능이 `backend/app/services/`로 통합됨
  - `src/image_processor.py` → `backend/app/services/image_processor_service.py`
  - `src/menu_matcher.py` → `backend/app/services/menu_matcher_service.py`
  - `src/korean_name_generator.py` → `backend/app/services/korean_name_service.py`
  - `src/clients/openai_client.py` → `backend/app/services/openai_service.py`
- ❌ `src/menus.db` - SQLite DB는 더 이상 사용하지 않음 (PostgreSQL 사용)
- ❌ `notebooks/` - 개발 노트북 (참조 없음)

---

## 🔍 상세 분석

### 1. 코드 의존성 확인

**Backend 코드에서 외부 파일 참조 여부:**
```bash
# 검색 결과: backend/ 폴더 내부에서 src/, notebooks/, 루트 파일을 import하는 코드 없음
grep -r "from src\|import src\|from clients\|from menu_matcher\|from image_processor\|from korean_name_generator" backend/
# 결과: 일치 없음
```

**Backend가 사용하는 데이터베이스:**
- ✅ PostgreSQL (PostGIS) - `backend/app/db/models.py`
- ✅ 메뉴 데이터는 `MenuItem` 테이블에서 조회 (`backend/app/services/menu_matcher_service.py`)
- ❌ SQLite (`src/menus.db`) - 더 이상 사용하지 않음

### 2. 파일 구조 비교

#### 이전 구조 (src/ 사용)
```
src/
├── image_processor.py      # OpenAI 이미지 분석
├── menu_matcher.py         # SQLite DB 사용
├── korean_name_generator.py
├── menus.db                # SQLite 데이터베이스
└── clients/
    └── openai_client.py
```

#### 현재 구조 (backend/ 독립적)
```
backend/app/services/
├── image_processor_service.py    # PostgreSQL 기반
├── menu_matcher_service.py       # PostgreSQL MenuItem 테이블 사용
├── korean_name_service.py
└── openai_service.py
```

---

## 📦 Dummy 폴더로 이동할 파일/폴더

다음 파일들은 backend/와 무관하므로 dummy 폴더로 이동 가능합니다:

### 폴더
1. **`src/`** (전체)
   - `src/image_processor.py`
   - `src/menu_matcher.py`
   - `src/korean_name_generator.py`
   - `src/api_handler.py`
   - `src/clients/`
   - `src/menus.db` ⚠️ **더 이상 필요 없음 (PostgreSQL 사용)**

2. **`notebooks/`** (전체)
   - `notebooks/dev.ipynb`
   - `notebooks/bibim.jpg`
   - `notebooks/폐기/`

### 파일
1. **`PROJECT_STATUS.md`** - 프로젝트 상태 문서
2. **`README_통합이미지처리시스템.md`** - 이전 시스템 문서
3. **`requirements.txt`** (루트) - backend/requirements.txt와 별개

---

## ✅ 확인 사항

### Backend 독립성 검증
- [x] Backend 코드가 외부 파일을 import하지 않음
- [x] Backend가 자체 requirements.txt를 보유
- [x] Backend가 자체 README.md를 보유
- [x] Backend가 자체 Docker 설정을 보유
- [x] 모든 서비스 로직이 backend/app/ 내부에 통합됨

### 데이터베이스
- [x] PostgreSQL (PostGIS) 사용
- [x] SQLite (`menus.db`) 미사용
- [x] Alembic 마이그레이션 사용

---

## 🎯 권장 작업 순서

1. **Dummy 폴더 생성**
   ```bash
   mkdir dummy
   ```

2. **이동할 파일/폴더 이동**
   ```bash
   # src 폴더 이동
   mv src dummy/
   
   # notebooks 폴더 이동
   mv notebooks dummy/
   
   # 문서 파일 이동
   mv PROJECT_STATUS.md dummy/
   mv README_통합이미지처리시스템.md dummy/
   mv requirements.txt dummy/  # 루트 requirements.txt
   ```

3. **확인**
   - Backend가 정상 작동하는지 테스트
   - Docker 빌드 및 실행 확인

---

## 📝 참고사항

### Backend에서 유지해야 할 파일들 (이미 위치함)
- `backend/structure.md` - 서비스 구조 문서 (backend/ 내부에 있어야 함)
- `backend/requirements.txt` - Backend 전용 의존성
- `backend/README.md` - Backend 실행 가이드
- `backend/.env` 또는 환경 변수 설정 (별도 관리 필요)

### 환경 변수 파일 (.env)
- `.env` 파일은 보안상 Git에 커밋하지 않음
- `backend/env_example.txt`를 참고하여 `.env` 생성
- Backend 실행 시 `backend/.env` 위치에서 로드됨

---

## ✅ 최종 결론

**backend/ 폴더로 이동해야 할 파일: 없음**

Backend는 이미 완전히 독립적으로 구성되어 있습니다. 
나머지 파일들(src/, notebooks/, 문서 파일들)은 dummy 폴더로 이동하셔도 Backend 동작에 전혀 영향을 주지 않습니다.

