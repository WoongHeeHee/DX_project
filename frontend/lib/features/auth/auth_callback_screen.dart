import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/api_repository.dart';

// 웹 환경에서만 dart:html 사용
import 'dart:html' as html if (dart.library.html) 'dart:html';

/// Google OAuth 리디렉션 콜백 화면
/// URL에서 id_token을 추출하여 자동 로그인 처리
class AuthCallbackScreen extends StatefulWidget {
  final Uri? uri;

  const AuthCallbackScreen({super.key, this.uri});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  final _apiRepository = ApiRepository();
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _processCallback();
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = '웹 환경에서만 사용할 수 있습니다.';
      });
    }
  }

  Future<void> _processCallback() async {
    // 페이지 로드 직후 URL을 즉시 확인
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // GoRouter의 state.uri가 있으면 우선 사용, 없으면 window.location 사용
      Uri uri;
      if (widget.uri != null) {
        uri = widget.uri!;
      } else if (kIsWeb) {
        final currentUrl = html.window.location.href;
        uri = Uri.parse(currentUrl);
        debugPrint('현재 URL: $currentUrl');
      } else {
        throw Exception('웹 환경에서만 사용할 수 있습니다.');
      }

      String? idToken;

      // 1. 쿼리 파라미터에서 추출 시도 (우선 id_token, 없다면 access_token도 체크)
      idToken = uri.queryParameters['id_token'] ??
          uri.queryParameters['access_token'];

      // 2. 해시 프래그먼트에서 추출 시도 (우선순위 높음 - Google OAuth Implicit Flow)
      if ((idToken == null || idToken.isEmpty) && uri.hasFragment) {
        final fragment = uri.fragment;
        debugPrint(
            '프래그먼트 내용: ${fragment.substring(0, fragment.length > 200 ? 200 : fragment.length)}...');

        if (fragment.isNotEmpty) {
          final hashParams = Uri.splitQueryString(fragment);
          // id_token 우선, 없으면 access_token도 허용 (일부 OAuth 구현 호환)
          idToken = hashParams['id_token'] ?? hashParams['access_token'];
          debugPrint('프래그먼트 파싱 결과 keys=${hashParams.keys}');
          if (idToken != null) {
            debugPrint('✅ 프래그먼트에서 id_token 추출 성공 (길이: ${idToken.length})');
          }
        }
      }

      // 3. 만약 여전히 id_token을 찾지 못했다면, window.location에서 직접 추출 시도
      if ((idToken == null || idToken.isEmpty) && kIsWeb) {
        final windowUri = Uri.parse(html.window.location.href);
        idToken = windowUri.queryParameters['id_token'] ??
            windowUri.queryParameters['access_token'];

        if (idToken == null && windowUri.hasFragment) {
          final hashParams = Uri.splitQueryString(windowUri.fragment);
          idToken = hashParams['id_token'] ?? hashParams['access_token'];
          debugPrint('window.location 프래그먼트 파싱 결과 keys=${hashParams.keys}');
        }
      }

      if (idToken == null || idToken.isEmpty) {
        debugPrint('❌ id_token을 찾을 수 없습니다.');
        debugPrint('URI: $uri');
        debugPrint('hasFragment: ${uri.hasFragment}');
        debugPrint('fragment: ${uri.fragment}');
        debugPrint('queryParameters: ${uri.queryParameters}');
        setState(() {
          _isProcessing = false;
          _errorMessage = 'id_token을 받을 수 없습니다. 로그인을 다시 시도해주세요.';
        });
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      debugPrint('✅ id_token 추출 완료, 백엔드에 전송 시작 (길이: ${idToken.length})');
      await _apiRepository.authService.googleLoginWithIdToken(idToken);
      debugPrint('✅ 백엔드 로그인 성공');

      // 사용자 정보 조회
      final user = await _apiRepository.authService.getCurrentUser();

      // locale 저장
      await _apiRepository.userService.setLocale(user.locale);

      if (!mounted) {
        return;
      }

      // URL 정리 (쿼리 파라미터와 해시 제거)
      if (kIsWeb) {
        final cleanUrl = html.window.location.origin + '/auth/callback';
        html.window.history.replaceState(null, '', cleanUrl);
      }

      // 온보딩 완료 여부 확인
      final isOnboardingComplete =
          user.country != null && user.birthYyyyMm != null;

      if (isOnboardingComplete) {
        context.go('/map');
      } else {
        context.go('/onboarding/language');
      }
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('❌ AuthCallbackScreen 오류 발생');
      debugPrint('───────────────────────────────────────────────────');
      debugPrint('에러 타입: ${e.runtimeType}');
      debugPrint('에러 메시지: $e');
      debugPrint('스택 트레이스: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════');

      String errorMsg = '로그인 처리 중 오류가 발생했습니다.\n\n';

      // 에러 타입별 상세 메시지
      if (e.toString().contains('서버에 연결할 수 없습니다') ||
          e.toString().contains('connectionError') ||
          e.toString().contains('CORS')) {
        errorMsg += '서버에 연결할 수 없습니다.\n';
        errorMsg += '가능한 원인:\n';
        errorMsg += '1. 백엔드 서버가 실행되지 않음\n';
        errorMsg += '2. CORS 설정 문제\n';
        errorMsg += '3. 네트워크 연결 문제';
      } else if (e.toString().contains('access_token')) {
        errorMsg += '백엔드 응답에 access_token이 없습니다.\n\n';
        errorMsg += '에러 상세:\n${e.toString()}';
      } else {
        errorMsg += '에러 상세:\n${e.toString()}';
      }

      // 디버그 모드에서는 스택 트레이스도 표시
      if (kDebugMode) {
        errorMsg += '\n\n[디버그 정보]\n';
        errorMsg += '타입: ${e.runtimeType}\n';
        errorMsg +=
            '스택: ${stackTrace.toString().substring(0, stackTrace.toString().length > 500 ? 500 : stackTrace.toString().length)}...';
      }

      setState(() {
        _isProcessing = false;
        _errorMessage = errorMsg;
      });

      // 에러가 발생해도 잠시 대기 후 로그인 화면으로 이동 (5초로 연장)
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        debugPrint('AuthCallbackScreen: 로그인 화면으로 돌아감');
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    '로그인 처리 중...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage ?? '오류가 발생했습니다.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red[700],
                          ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('로그인 화면으로 돌아가기'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
