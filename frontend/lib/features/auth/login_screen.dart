import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/api_repository.dart';
import '../../core/widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _apiRepository = ApiRepository();

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Google 로그인 (전체 페이지 리디렉션 방식)
      // 웹 환경에서는 전체 페이지가 Google 로그인 페이지로 리디렉션됨
      // 리디렉션 후 /auth/callback 경로에서 AuthCallbackScreen이 처리함
      await _apiRepository.authService.googleLogin();
      
      // 전체 페이지 리디렉션이 발생하지 않은 경우에만 실행됨
      // (일반적으로는 실행되지 않음)
      // 사용자 정보 조회
      final user = await _apiRepository.authService.getCurrentUser();
      
      // locale 저장
      await _apiRepository.userService.setLocale(user.locale);
      
      if (mounted) {
        // 온보딩 완료 여부 확인 (country가 있으면 온보딩 완료)
        if (user.country != null && user.birthYyyyMm != null) {
          // 온보딩 완료 - 홈 화면으로 이동
          context.go('/explore');
        } else {
          // 온보딩 미완료 - 온보딩 화면으로 이동
          context.go('/onboarding/language');
        }
      }
    } catch (e) {
      // 전체 페이지 리디렉션이 발생하면 이 catch 블록은 실행되지 않음
      // (페이지가 리디렉션되므로)
      // 하지만 리디렉션이 실패한 경우를 대비하여 에러 처리
      if (mounted) {
        // 에러 메시지 정리
        String errorMessage = '로그인에 실패했습니다.';
        if (e.toString().contains('id_token')) {
          // 전체 페이지 리디렉션 방식에서는 id_token이 null일 수 있음 (정상)
          // 이 경우는 무시하고 리디렉션을 기다림
          debugPrint('LoginScreen: 전체 페이지 리디렉션 중 (id_token null은 정상)');
          return;
        } else if (e.toString().contains('취소')) {
          errorMessage = '로그인이 취소되었습니다.';
        } else {
          errorMessage = '로그인 오류: ${e.toString()}';
        }
        
        // 에러 화면 대신 스낵바로 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () {
                // 다시 시도
                _handleGoogleSignIn(context);
              },
            ),
          ),
        );
      }
    } finally {
      // 전체 페이지 리디렉션이 발생하면 이 finally 블록도 실행되지 않을 수 있음
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 상단 섹션: 로고 및 환영 메시지
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    Text('환영합니다!', style: textTheme.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      '간편하게 구글로 로그인하고 Apex 시장의 최신 정보를 확인하세요.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),

                // 하단 섹션: 버튼
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 구글 로그인 버튼 (디자인: ElevatedButton.icon 사용)
                    ElevatedButton.icon(
                      onPressed: () => _handleGoogleSignIn(context),
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          // Google 로고 이미지가 없을 경우 아이콘으로 대체
                          return const Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: AppColors.white,
                          );
                        },
                      ),
                      label: Text(
                        'Google로 로그인',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 가게 제보하기 버튼
                    OutlinedButton(
                      onPressed: () {
                        context.push('/report/guide');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        '가게 제보하기',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
