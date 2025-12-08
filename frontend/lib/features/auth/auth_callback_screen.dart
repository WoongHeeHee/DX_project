import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/api_repository.dart';

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
      } else {
        final currentUrl = html.window.location.href;
        uri = Uri.parse(currentUrl);
      }
      
      String? idToken;
      
      // 1. 쿼리 파라미터에서 추출 시도
      idToken = uri.queryParameters['id_token'];
      
      // 2. 해시 프래그먼트에서 추출 시도
      if ((idToken == null || idToken.isEmpty) && uri.hasFragment) {
        final fragment = uri.fragment;
        
        // 해시에서 id_token 추출
        if (fragment.contains('id_token=')) {
          final hashParams = Uri.splitQueryString(fragment);
          idToken = hashParams['id_token'];
        }
      }
      
      // 3. 만약 여전히 id_token을 찾지 못했다면, window.location에서 직접 추출 시도
      if ((idToken == null || idToken.isEmpty) && kIsWeb) {
        final windowUri = Uri.parse(html.window.location.href);
        idToken = windowUri.queryParameters['id_token'];
        
        if (idToken == null && windowUri.hasFragment) {
          final hashParams = Uri.splitQueryString(windowUri.fragment);
          idToken = hashParams['id_token'];
        }
      }

      if (idToken == null || idToken.isEmpty) {
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

      await _apiRepository.authService.googleLoginWithIdToken(idToken);

      // 사용자 정보 조회
      final user = await _apiRepository.authService.getCurrentUser();

      // locale 저장
      await _apiRepository.userService.setLocale(user.locale);

      if (!mounted) {
        return;
      }

      // URL 정리 (쿼리 파라미터와 해시 제거)
      final cleanUrl = html.window.location.origin + '/auth/callback';
      html.window.history.replaceState(null, '', cleanUrl);

      // 온보딩 완료 여부 확인
      final isOnboardingComplete = user.country != null && user.birthYyyyMm != null;

      if (isOnboardingComplete) {
        context.go('/map');
      } else {
        context.go('/onboarding/language');
      }

    } catch (e) {
      debugPrint('AuthCallbackScreen 오류: ${e.runtimeType} - $e');
      
      String errorMsg = '로그인 처리 중 오류가 발생했습니다.';
      if (e.toString().contains('서버에 연결할 수 없습니다') || 
          e.toString().contains('connectionError') ||
          e.toString().contains('CORS')) {
        errorMsg = '서버에 연결할 수 없습니다.\n네트워크 연결과 서버 주소(http://localhost:8000)를 확인해주세요.';
      } else {
        errorMsg += '\n${e.toString()}';
      }
      
      setState(() {
        _isProcessing = false;
        _errorMessage = errorMsg;
      });
      
      // 에러가 발생해도 잠시 대기 후 로그인 화면으로 이동
      await Future.delayed(const Duration(seconds: 3));
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage ?? '오류가 발생했습니다.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('로그인 화면으로 돌아가기'),
                  ),
                ],
              ),
      ),
    );
  }
}

