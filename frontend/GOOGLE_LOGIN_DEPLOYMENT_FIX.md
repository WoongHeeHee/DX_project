# 🔐 배포 환경 구글 로그인 문제 해결 가이드

## 📋 문제 진단

배포 환경에서 구글 로그인이 작동하지 않는 경우, 다음을 확인하세요:

### 1. Google Cloud Console 설정 확인

**가장 흔한 원인**: 배포 환경의 redirect URI가 Google Cloud Console에 등록되지 않았습니다.

#### 확인 방법:

1. **Google Cloud Console 접속**
   - https://console.cloud.google.com/
   - 프로젝트 선택

2. **OAuth 2.0 Client ID 확인**
   - APIs & Services → Credentials
   - OAuth 2.0 Client IDs 클릭
   - 사용 중인 Client ID 선택

3. **Authorized redirect URIs 확인**
   - 다음 URI들이 등록되어 있어야 합니다:
     - **로컬 개발**: `http://localhost:50000/auth/callback`
     - **배포 환경**: `https://yourdomain.com/auth/callback` (실제 도메인으로 변경)
   
   ⚠️ **중요**: 
   - `http://`와 `https://`는 다른 URI로 인식됩니다
   - 도메인 뒤에 `/`가 없어야 합니다 (예: `/auth/callback` ✅, `/auth/callback/` ❌)
   - 포트 번호가 있으면 포함해야 합니다 (로컬 개발 환경)

4. **Authorized JavaScript origins 확인**
   - 다음 origins가 등록되어 있어야 합니다:
     - **로컬 개발**: `http://localhost:50000`
     - **배포 환경**: `https://yourdomain.com` (실제 도메인으로 변경)

### 2. 브라우저 콘솔 확인

배포 환경에서 구글 로그인 버튼을 클릭한 후:

1. **브라우저 개발자 도구 열기** (F12)
2. **Console 탭 확인**
3. 다음 로그들을 확인하세요:

```
🔐 Google 로그인 시작 - 전체 페이지 리디렉션
📍 현재 환경 정보:
  - hostname: yourdomain.com
  - origin: https://yourdomain.com
  - protocol: https:
🔑 Google Client ID: 584089307412-hfnij6j...
🔄 Redirect URI: https://yourdomain.com/auth/callback
```

#### 문제가 있는 경우:

- **"Google Client ID가 설정되지 않았습니다"**
  - `index.html`의 `window.ENV.GOOGLE_CLIENT_ID` 확인
  - 배포 빌드에 `index.html`이 포함되었는지 확인

- **"Google Identity Services 초기화가 완료되지 않았습니다"**
  - `index.html`의 Google Identity Services 스크립트가 로드되었는지 확인
  - 네트워크 탭에서 `https://accounts.google.com/gsi/client` 로드 확인

- **리디렉션 후 id_token을 찾을 수 없음**
  - Google Cloud Console의 redirect URI 설정 확인
  - 브라우저 콘솔의 에러 메시지 확인

### 3. 네트워크 탭 확인

1. **브라우저 개발자 도구 → Network 탭**
2. **구글 로그인 버튼 클릭**
3. **다음 요청들을 확인**:

   - `https://accounts.google.com/o/oauth2/v2/auth?...` 요청
     - Status: 302 (리디렉션) 또는 200이어야 함
     - 400 에러: redirect URI가 등록되지 않았을 가능성
     - 403 에러: Client ID가 잘못되었거나 승인되지 않음

   - `/auth/callback?...` 요청
     - URL에 `id_token=...` 또는 hash fragment에 `#id_token=...`가 있어야 함

### 4. 배포 환경 설정 확인

#### index.html 확인

`frontend/web/index.html` 파일에서:

```javascript
window.ENV = {
  API_BASE_URL: 'https://api.yourdomain.com',  // 실제 도메인으로 변경
  GOOGLE_CLIENT_ID: '584089307412-hfnij6j84iqfr5gj3m45ef7ue1f3k5je.apps.googleusercontent.com',
  GOOGLE_MAPS_API_KEY: 'AIzaSyByKS4TYVcqPYor-594VP0BTwcQPKaEQFg',
};
```

⚠️ **중요**: 
- 배포 환경에서는 `https://`를 사용해야 합니다
- `GOOGLE_CLIENT_ID`가 올바른지 확인하세요

#### Flutter 빌드 확인

배포 빌드를 생성할 때 `index.html`이 포함되는지 확인:

```bash
cd frontend
flutter build web
```

빌드 후 `build/web/index.html` 파일을 확인하여 `window.ENV` 설정이 포함되어 있는지 확인하세요.

## 🔧 해결 방법

### 방법 1: Google Cloud Console에 Redirect URI 추가

1. Google Cloud Console → APIs & Services → Credentials
2. OAuth 2.0 Client ID 선택
3. **Authorized redirect URIs**에 추가:
   ```
   https://yourdomain.com/auth/callback
   ```
   (실제 배포 도메인으로 변경)

4. **Authorized JavaScript origins**에 추가:
   ```
   https://yourdomain.com
   ```
   (실제 배포 도메인으로 변경)

5. **저장** 클릭

6. **5-10분 대기** (설정이 전파되는데 시간이 걸릴 수 있음)

7. **브라우저 캐시 삭제** 후 다시 시도

### 방법 2: index.html 확인 및 수정

1. `frontend/web/index.html` 파일 열기
2. `window.ENV.GOOGLE_CLIENT_ID` 확인
3. 배포 환경의 도메인으로 올바르게 설정되었는지 확인
4. Flutter 빌드 재생성:
   ```bash
   cd frontend
   flutter build web --release
   ```
5. 배포 재시도

### 방법 3: 브라우저 콘솔에서 직접 확인

배포 환경에서 브라우저 콘솔을 열고 다음을 실행:

```javascript
// window.ENV 확인
console.log('window.ENV:', window.ENV);
console.log('GOOGLE_CLIENT_ID:', window.ENV?.GOOGLE_CLIENT_ID);

// triggerGoogleSignIn 함수 확인
console.log('triggerGoogleSignIn:', typeof window.triggerGoogleSignIn);
```

예상 결과:
- `window.ENV`가 객체여야 함
- `GOOGLE_CLIENT_ID`가 비어있지 않아야 함
- `triggerGoogleSignIn`이 `"function"`이어야 함

## 📊 체크리스트

배포 환경에서 구글 로그인이 작동하려면:

- [ ] Google Cloud Console에 배포 환경의 redirect URI가 등록됨
  - `https://yourdomain.com/auth/callback`
- [ ] Google Cloud Console에 배포 환경의 JavaScript origin이 등록됨
  - `https://yourdomain.com`
- [ ] `index.html`의 `window.ENV.GOOGLE_CLIENT_ID`가 올바르게 설정됨
- [ ] Flutter 빌드에 `index.html`이 포함됨
- [ ] 배포 환경이 HTTPS를 사용함 (Google OAuth는 HTTPS 필수)
- [ ] 브라우저 콘솔에 에러가 없음
- [ ] 네트워크 탭에서 Google OAuth 요청이 성공함

## 🐛 일반적인 에러 메시지

### "redirect_uri_mismatch"

**원인**: Google Cloud Console에 등록된 redirect URI와 실제 사용하는 URI가 일치하지 않음

**해결**: Google Cloud Console의 Authorized redirect URIs에 정확한 URI 추가

### "access_denied"

**원인**: 사용자가 Google 로그인을 취소했거나, OAuth 동의 화면 설정 문제

**해결**: Google Cloud Console의 OAuth consent screen 설정 확인

### "invalid_client"

**원인**: Client ID가 잘못되었거나 삭제됨

**해결**: `index.html`의 `GOOGLE_CLIENT_ID` 확인 및 Google Cloud Console에서 Client ID 확인

### "id_token을 받을 수 없습니다"

**원인**: Google OAuth 리디렉션 후 URL에 id_token이 포함되지 않음

**해결**: 
1. Google Cloud Console의 redirect URI 설정 확인
2. 브라우저 콘솔의 디버깅 로그 확인
3. 네트워크 탭에서 리디렉션 URL 확인

## 📞 추가 도움

문제가 계속되면 다음 정보를 수집하여 문의하세요:

1. **브라우저 콘솔 로그** (전체)
2. **네트워크 탭 스크린샷** (Google OAuth 요청)
3. **배포 환경 URL**
4. **Google Cloud Console의 OAuth 2.0 Client ID 설정 스크린샷** (민감한 정보는 가림)

