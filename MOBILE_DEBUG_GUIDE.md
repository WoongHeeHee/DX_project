# 모바일 브라우저 콘솔 로그 확인 가이드

## Android (Chrome)

### 방법 1: Chrome Remote Debugging (권장)

1. **PC에서 Chrome 열기**
   - Chrome 브라우저 실행

2. **모바일 기기 설정**
   - 설정 → 개발자 옵션 → USB 디버깅 활성화
   - USB 케이블로 PC와 연결
   - "USB 디버깅 허용" 팝업에서 확인

3. **Chrome에서 디버깅 시작**
   - PC Chrome에서 `chrome://inspect` 주소 입력
   - "Remote devices" 섹션에서 모바일 기기 확인
   - "inspect" 클릭

4. **콘솔 확인**
   - 열린 개발자 도구에서 "Console" 탭 선택
   - Flutter 앱의 `debugPrint` 로그 확인 가능

### 방법 2: Chrome DevTools (무선)

1. **모바일과 PC가 같은 Wi-Fi에 연결**
2. **모바일 Chrome에서**
   - `chrome://inspect` 입력
   - "Discover USB devices" 옆의 "Port forwarding" 설정
3. **PC Chrome에서**
   - `chrome://inspect` 입력
   - 모바일 기기 확인 후 "inspect"

## iOS (Safari)

### 방법 1: Safari Web Inspector

1. **Mac에서 Safari 설정**
   - Safari → 환경설정 → 고급
   - "메뉴 막대에서 개발자용 메뉴 보기" 체크

2. **iOS 기기 설정**
   - 설정 → Safari → 고급 → 웹 검사기 활성화

3. **USB로 연결**
   - iPhone/iPad를 Mac에 USB로 연결
   - "신뢰" 선택

4. **Safari에서 디버깅**
   - Mac Safari에서 개발자 → [기기명] → [웹페이지]
   - Web Inspector 창에서 Console 탭 확인

### 방법 2: Eruda (모바일 브라우저 콘솔)

코드에 Eruda를 추가하여 모바일에서 직접 콘솔 확인:

```html
<script src="https://cdn.jsdelivr.net/npm/eruda"></script>
<script>eruda.init();</script>
```

## 대안: 화면에 에러 표시

현재 코드가 수정되어 에러 메시지가 화면에 표시됩니다:
- `auth_callback_screen.dart`에서 에러 발생 시 상세 메시지 표시
- 디버그 모드에서는 스택 트레이스도 포함

## 빠른 확인 방법

1. **모바일 브라우저에서 에러 화면 확인**
   - 로그인 실패 시 표시되는 에러 메시지 확인
   - 스크린샷 촬영

2. **PC 브라우저에서 테스트**
   - 같은 URL로 PC에서 접속
   - F12로 개발자 도구 열기
   - Console 탭에서 로그 확인

3. **Network 탭 확인**
   - 개발자 도구 → Network 탭
   - `/auth/google` 요청 확인
   - 응답 상태 코드 및 본문 확인

