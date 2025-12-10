# 🔍 코드 분석 리포트: 디자인 통합 과정에서 발견된 문제 후보

## 📋 분석 개요

`backend/`, `frontend/`, `structure.md`, `API_SPECIFICATION.md`를 참고하여 **원래 의도와 다르게 동작하는 코드**를 찾아 정리했습니다.

---

## 🎯 문제 1: 한국 이름 생성 로직 - 더미 데이터 사용 중

### 1) 파일 경로
```
frontend/lib/features/onboarding/onboarding_loading_screen.dart
```

### 2) 어떤 코드가 원래 의도와 다른지

**라인 35-103**: 실제 API 호출 코드가 주석 처리되어 있고, 더미 데이터 생성 함수를 사용 중입니다.

```35:103:frontend/lib/features/onboarding/onboarding_loading_screen.dart
  Future<void> _generateKoreanName() async {
    try {
      // TODO: 서버 연결 시 주석 해제
      // // 한국 이름 생성 API 호출
      // debugPrint('한국 이름 생성 요청: ${widget.inputName}');
      // final koreanNameResponse =
      //     await _apiRepository.userService.generateKoreanName(widget.inputName);
      // ...
      
      // 임시: 서버 연결 없이 더미 데이터 사용
      await Future.delayed(const Duration(seconds: 2)); // 로딩 시간 시뮬레이션
      
      // 입력 이름에 따라 더미 한국 이름 생성
      final dummyKoreanName = _generateDummyKoreanName(widget.inputName);
      final dummyEnglishPronunciation = _generateDummyEnglishPronunciation(widget.inputName);
      // ...
    }
  }

  // 더미 한국 이름 생성 (입력 이름의 첫 글자를 기반으로)
  String _generateDummyKoreanName(String inputName) {
    // 간단한 매핑 (실제로는 서버에서 생성)
    final nameMap = {
      'a': '김', 'b': '이', 'c': '박', // ...
    };
    // ...
  }
```

### 3) 왜 원래 목표에서 벗어나는지

- **API 명세서 (`API_SPECIFICATION.md`)**에 따르면 `POST /users/generate-korean-name` 엔드포인트가 존재합니다.
- **백엔드 서비스 (`backend/app/services/korean_name_service.py`)**가 정상적으로 구현되어 있습니다 (OpenAI GPT-4o 사용).
- **프론트엔드 서비스 (`frontend/lib/data/services/user_service.dart`)**의 `generateKoreanName()` 메서드도 정상 구현되어 있습니다.
- 하지만 **실제 화면에서는 더미 데이터를 사용**하고 있어, 서버 연동이 작동하지 않습니다.

### 4) 실제 예상되는 정상 동작

1. 사용자가 이름을 입력하고 "확인" 버튼 클릭
2. `OnboardingLoadingScreen`으로 이동
3. `_apiRepository.userService.generateKoreanName(widget.inputName)` 호출
4. 백엔드 `POST /users/generate-korean-name` API 호출
5. `KoreanNameService.generate_korean_name()`이 OpenAI를 통해 한국 이름 생성
6. 생성된 이름을 화면에 표시

### 5) 제안되는 수정안

```dart
// frontend/lib/features/onboarding/onboarding_loading_screen.dart

// 라인 8 주석 해제
import "../../data/repositories/api_repository.dart";

// 라인 25 주석 해제
final _apiRepository = ApiRepository();

Future<void> _generateKoreanName() async {
  try {
    // TODO 제거하고 실제 API 호출
    debugPrint('한국 이름 생성 요청: ${widget.inputName}');
    final koreanNameResponse =
        await _apiRepository.userService.generateKoreanName(widget.inputName);
    
    debugPrint(
        '한국 이름 생성 응답: ${koreanNameResponse.koreanName}, ${koreanNameResponse.englishPronunciation}');
    
    if (koreanNameResponse.koreanName.isEmpty) {
      throw Exception('한국 이름이 생성되지 않았습니다.');
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OnboardingNameConfirmScreen(
            inputName: widget.inputName,
            koreanName: koreanNameResponse.koreanName,
            englishPronunciation: koreanNameResponse.englishPronunciation,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('한국 이름 생성 에러: $e');
    if (mounted) {
      // 에러 발생 시 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('한국 이름 생성에 실패했습니다. 다시 시도해주세요.'),
          duration: const Duration(seconds: 3),
        ),
      );
      // 에러 화면으로 이동 또는 이전 화면으로 돌아가기
      Navigator.of(context).pop();
    }
  }
}

// _generateDummyKoreanName, _generateDummyEnglishPronunciation 함수 삭제
```

---

## 🎯 문제 2: 드롭다운 리스트 - asset 경로 불일치 및 "기타" 항목 차이

### 1) 파일 경로
- `frontend/lib/features/onboarding/onboarding_country_screen.dart` (라인 29-140)
- `frontend/lib/features/home/explore_screen.dart` (라인 313-419)

### 2) 어떤 코드가 원래 의도와 다른지

**문제 2-1: Asset 경로 불일치**

- **온보딩 화면** (`onboarding_country_screen.dart`): `assets/designs/images/` 경로 사용
- **탐색 화면** (`explore_screen.dart`): `assets/images/` 경로 사용

```33:48:frontend/lib/features/onboarding/onboarding_country_screen.dart
    CountryFilter(
      id: "country_jp",
      name: "일본",
      flagImageUrl: "assets/designs/images/JP.gif",
    ),
    // ...
    CountryFilter(
      id: "country_kr",
      name: "한국",
      flagImageUrl: null,  // ⚠️ 한국 국기 없음
    ),
```

```317:333:frontend/lib/features/home/explore_screen.dart
    CountryFilter(
      id: "country_jp",
      name: "일본",
      flagImageUrl: "assets/images/JP.gif",
    ),
    // ...
    CountryFilter(
      id: "country_kr",
      name: "한국",
      flagImageUrl: "assets/images/KR.png", // ⚠️ 다른 경로와 확장자
    ),
```

**문제 2-2: "기타" 항목 유무 차이**

- **온보딩 화면**: "기타" 항목 **있음** (라인 135-139)
- **탐색 화면**: "기타" 항목 **없음**

```135:139:frontend/lib/features/onboarding/onboarding_country_screen.dart
    CountryFilter(
      id: "country_other",
      name: "기타",
      flagImageUrl: null,
    ),
  ];
```

### 3) 왜 원래 목표에서 벗어나는지

- **구조 문서 (`structure.md`)**에 따르면 국가 선택은 온보딩 과정에서 이루어지며, 이후 탐색 화면에서도 동일한 국가 정보를 사용해야 합니다.
- 두 화면에서 다른 asset 경로를 사용하면:
  - 로컬 환경: `assets/designs/images/`에 파일이 있을 수 있음 → 정상 동작
  - 배포 환경: 빌드 시 `assets/images/`에만 파일이 포함될 수 있음 → 국기 로드 실패
- "기타" 항목이 온보딩에는 있지만 탐색에는 없으면, 사용자가 "기타"를 선택했을 때 탐색 화면에서 해당 국가를 표시할 수 없습니다.

### 4) 실제 예상되는 정상 동작

1. 두 화면 모두 **동일한 asset 경로** 사용
2. 두 화면 모두 **동일한 국가 리스트** 사용 (또는 "기타" 항목의 포함 여부를 명확히 정의)
3. 로컬/배포 환경 모두에서 동일하게 동작

### 5) 제안되는 수정안

**옵션 A: `assets/images/` 경로로 통일 (권장)**

```dart
// frontend/lib/features/onboarding/onboarding_country_screen.dart
// 모든 flagImageUrl을 assets/images/로 변경

final List<CountryFilter> countries = [
  CountryFilter(
    id: "country_jp",
    name: "일본",
    flagImageUrl: "assets/images/JP.gif",  // 변경
  ),
  // ...
  CountryFilter(
    id: "country_kr",
    name: "한국",
    flagImageUrl: "assets/images/KR.png",  // null에서 변경
  ),
  // ...
  CountryFilter(
    id: "country_other",
    name: "기타",
    flagImageUrl: null,
  ),
];
```

**옵션 B: 공통 상수로 추출 (더 나은 방법)**

```dart
// frontend/lib/core/constants/country_constants.dart (새 파일)
class CountryConstants {
  static const List<CountryFilter> countries = [
    CountryFilter(
      id: "country_jp",
      name: "일본",
      flagImageUrl: "assets/images/JP.gif",
    ),
    // ...
    CountryFilter(
      id: "country_kr",
      name: "한국",
      flagImageUrl: "assets/images/KR.png",
    ),
    // ... (모든 국가)
    CountryFilter(
      id: "country_other",
      name: "기타",
      flagImageUrl: null,
    ),
  ];
  
  // "기타" 제외 버전 (탐색 화면용)
  static List<CountryFilter> get countriesWithoutOther =>
      countries.where((c) => c.id != "country_other").toList();
}

// 두 화면 모두에서 사용
import '../../core/constants/country_constants.dart';

// 온보딩 화면
final List<CountryFilter> countries = CountryConstants.countries;

// 탐색 화면
final List<CountryFilter> countries = CountryConstants.countriesWithoutOther;
```

**"기타" 항목 처리 정책 결정 필요:**
- 온보딩에서만 사용하고 탐색에서는 제외할지
- 두 화면 모두에서 사용할지
- 사용자가 "기타"를 선택했을 때 탐색 화면에서 어떻게 처리할지

---

## 🎯 문제 3: 로그인 버튼 클릭 시 로컬/배포 환경별 동작 차이

### 1) 파일 경로
- `frontend/lib/features/auth/login_screen.dart` (라인 20-94)
- `frontend/lib/data/services/auth_service.dart` (라인 16-61)
- `frontend/lib/features/auth/auth_callback_screen.dart` (라인 40-167)
- `frontend/web/index.html` (라인 110-149)

### 2) 어떤 코드가 원래 의도와 다른지

**웹 환경 로그인 플로우:**

1. `login_screen.dart`에서 `_apiRepository.authService.googleLogin()` 호출
2. `auth_service.dart`에서 웹 환경일 경우 리디렉션 예외를 던짐
3. `login_screen.dart`에서 리디렉션 예외를 무시하고 로딩 상태 유지
4. `index.html`의 JavaScript에서 전체 페이지 리디렉션 수행
5. Google OAuth 후 `/auth/callback`으로 리디렉션
6. `auth_callback_screen.dart`에서 처리

**문제점:**
- 배포 환경에서 리디렉션이 제대로 처리되지 않거나, 콜백 후 온보딩으로 넘어가는 과정에서 문제가 발생할 수 있습니다.

```66:71:frontend/lib/features/auth/login_screen.dart
      // 웹 환경에서 리디렉션 예외는 정상적인 동작이므로 무시
      if (kIsWeb && e.toString().contains('리디렉션')) {
        debugPrint('✅ 웹 환경 리디렉션 예외 - 정상 동작입니다. 리디렉션 대기 중...');
        // 리디렉션이 곧 발생할 것이므로 로딩 상태 유지
        return;
      }
```

### 3) 왜 원래 목표에서 벗어나는지

- **구조 문서 (`structure.md`)**에 따르면 "google login 버튼 클릭" → "다음 화면: Google OAuth 로그인 화면"이어야 합니다.
- 현재 코드는 웹 환경에서 리디렉션 예외를 던지고 무시하는 방식으로 처리하는데, 이는 다음과 같은 문제를 일으킬 수 있습니다:
  - 배포 환경에서 Google OAuth 설정이 다를 경우 리디렉션이 실패할 수 있음
  - 콜백 후 사용자 정보 조회 시 오류가 발생하면 온보딩으로 넘어가지 않고 에러 상태에 머물 수 있음

### 4) 실제 예상되는 정상 동작

1. 로그인 버튼 클릭
2. Google OAuth 화면으로 리디렉션 (웹 환경)
3. 사용자가 로그인 완료
4. `/auth/callback`으로 리디렉션
5. `auth_callback_screen.dart`에서 id_token 추출
6. 백엔드에 로그인 요청
7. 사용자 정보 조회
8. 온보딩 완료 여부 확인
9. 온보딩 미완료 시 → `/onboarding/language`로 이동
10. 온보딩 완료 시 → `/explore` 또는 `/map`으로 이동

### 5) 제안되는 수정안

**현재 코드는 대체로 올바르지만, 에러 처리 강화 필요:**

```dart
// frontend/lib/features/auth/auth_callback_screen.dart
// 라인 167 이후에 더 명확한 에러 처리 추가

} catch (e, stackTrace) {
  debugPrint('═══════════════════════════════════════════════════');
  debugPrint('❌ AuthCallbackScreen 에러 발생');
  debugPrint('에러 타입: ${e.runtimeType}');
  debugPrint('에러 메시지: $e');
  debugPrint('스택 트레이스: $stackTrace');
  debugPrint('═══════════════════════════════════════════════════');
  
  if (!mounted) return;
  
  setState(() {
    _isProcessing = false;
    _errorMessage = '로그인 처리 중 오류가 발생했습니다: ${e.toString()}';
  });
  
  // 5초 후 로그인 화면으로 복귀
  await Future.delayed(const Duration(seconds: 5));
  if (mounted) {
    context.go('/login');
  }
}
```

**또한 `login_screen.dart`에서 리디렉션 예외 처리 개선:**

```dart
// frontend/lib/features/auth/login_screen.dart
// 라인 66-71 개선

// 웹 환경에서 리디렉션 예외는 정상적인 동작이므로 무시
if (kIsWeb && (e.toString().contains('리디렉션') || 
               e.toString().contains('Google 로그인 리디렉션'))) {
  debugPrint('✅ 웹 환경 리디렉션 예외 - 정상 동작입니다. 리디렉션 대기 중...');
  // 리디렉션이 곧 발생할 것이므로 로딩 상태 유지
  // 하지만 타임아웃을 설정하여 무한 대기 방지
  Future.delayed(const Duration(seconds: 30), () {
    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 타임아웃이 발생했습니다. 다시 시도해주세요.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  });
  return;
}
```

---

## 📊 문제 우선순위 요약

| 우선순위 | 문제 | 심각도 | 영향 범위 |
|---------|------|--------|----------|
| 🔴 **HIGH** | 문제 1: 한국 이름 생성 더미 데이터 사용 | 높음 | 온보딩 핵심 기능 |
| 🟡 **MEDIUM** | 문제 2: 드롭다운 asset 경로 불일치 | 중간 | UI 일관성, 배포 환경 |
| 🟢 **LOW** | 문제 3: 로그인 환경별 동작 차이 | 낮음 | 에러 처리 개선 |

---

## 🔧 추가 권장사항

1. **공통 상수 파일 생성**: 국가 리스트, asset 경로 등을 중앙 관리
2. **환경 변수 활용**: 로컬/배포 환경별 asset 경로를 환경 변수로 관리
3. **에러 처리 강화**: 모든 API 호출에 대한 명확한 에러 처리 및 사용자 피드백
4. **통합 테스트**: 로컬/배포 환경에서 동일하게 동작하는지 확인

---

## 📝 참고 파일

- `backend/app/services/korean_name_service.py` - 한국 이름 생성 서비스 (정상 구현됨)
- `frontend/lib/data/services/user_service.dart` - 사용자 API 서비스 (정상 구현됨)
- `frontend/lib/data/services/auth_service.dart` - 인증 서비스
- `API_SPECIFICATION.md` - API 명세서
- `structure.md` - 화면 구조 문서

