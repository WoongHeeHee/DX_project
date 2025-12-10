# 배포 환경 문제 해결 가이드

## 현재 문제 진단

### 문제 1: 404 에러 - 백엔드 API 경로를 찾을 수 없음
**증상**: `POST https://sijanggo.com/auth/google 404 (Not Found)`

**원인**: Cloudflare 터널 설정에서 백엔드가 올바르게 라우팅되지 않음

**해결 방법**:

#### Cloudflare Tunnel config.yml 확인

`C:\Users\[사용자명]\.cloudflared\config.yml` 파일을 확인하세요:

```yaml
tunnel: [Tunnel-UUID]
credentials-file: C:/Users/[사용자명]/.cloudflared/[Tunnel-UUID].json

ingress:
  # 프론트엔드 (Flutter Web)
  - hostname: sijanggo.com
    service: http://localhost:50000
  
  # 백엔드 API (중요!)
  - hostname: api.sijanggo.com
    service: http://localhost:8000
  
  # 기본 규칙 (모든 다른 요청)
  - service: http_status:404
```

**중요**: 백엔드를 별도 서브도메인(`api.sijanggo.com`)으로 라우팅하거나, 경로 기반 라우팅을 사용해야 합니다.

#### 옵션 1: 서브도메인 사용 (권장)

1. **Cloudflare DNS 설정**:
   - Type: `CNAME`
   - Name: `api`
   - Target: `[Tunnel-UUID].cfargotunnel.com`

2. **config.yml 수정**:
```yaml
ingress:
  - hostname: sijanggo.com
    service: http://localhost:50000
  - hostname: api.sijanggo.com
    service: http://localhost:8000
  - service: http_status:404
```

3. **프론트엔드 index.html 수정 필요**:
   - 프로덕션 환경에서 `API_BASE_URL`을 `https://api.sijanggo.com`으로 설정

#### 옵션 2: 경로 기반 라우팅 (복잡함)

```yaml
ingress:
  # 백엔드 API 경로
  - path: /auth/*
    service: http://localhost:8000
  - path: /users/*
    service: http://localhost:8000
  - path: /markets/*
    service: http://localhost:8000
  # ... 모든 API 경로
  # 프론트엔드 (기본)
  - service: http://localhost:50000
```

### 문제 2: URL 프래그먼트 파싱 오류
**증상**: `id_token`이 경로로 인식됨

**원인**: GoRouter가 프래그먼트를 제대로 파싱하지 못함

**해결**: 이미 코드 수정 완료 - `app_router.dart`에서 `window.location.hash`를 직접 확인하도록 수정됨

## 수정 완료 내역

1. ✅ `app_router.dart` - 프래그먼트 파싱 개선
2. ✅ `auth_callback_screen.dart` - 에러 메시지 개선
3. ✅ `auth_service.dart` - 응답 검증 강화

## 다음 단계

1. **Cloudflare Tunnel config.yml 확인 및 수정**
2. **Tunnel 재시작**: `cloudflared tunnel run [tunnel-name]`
3. **프론트엔드 재빌드**: `flutter build web`
4. **테스트**: 배포 환경에서 다시 로그인 시도

