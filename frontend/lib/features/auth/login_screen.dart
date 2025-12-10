import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/responsive_helper.dart';
import '../../core/widgets/responsive_padding.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/api_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _apiRepository = ApiRepository();
  Timer? _timeoutTimer;

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('🔐 Google 로그인 버튼 클릭됨');
    debugPrint('═══════════════════════════════════════════════════');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 웹 환경: GoogleAuthServiceWeb이 전체 페이지 리디렉션을 수행
      // 리디렉션 후 /auth/callback에서 AuthCallbackScreen이 처리
      // 모바일 환경: GoogleAuthServiceMobile이 직접 id_token을 받아서 처리
      debugPrint('🚀 authService.googleLogin() 호출 시작...');
      
      // 웹 환경에서 리디렉션 대기 시 타임아웃 설정
      if (kIsWeb) {
        _timeoutTimer = Timer(const Duration(seconds: 30), () {
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
      }
      
      await _apiRepository.authService.googleLogin();
      _timeoutTimer?.cancel();
      debugPrint('⚠️ authService.googleLogin() 완료 - 이는 웹 환경에서는 예상치 못한 동작입니다.');

      // 웹 환경에서는 리디렉션이 발생하므로 여기까지 도달하지 않음
      // 모바일 환경에서만 여기까지 도달
      if (!mounted) return;

      // 모바일 환경: 로그인 성공 후 사용자 정보 확인
      final user = await _apiRepository.authService.getCurrentUser();
      
      // 온보딩 완료 여부 확인
      final isOnboardingComplete =
          user.country != null && user.birthYyyyMm != null;

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (isOnboardingComplete) {
        context.go('/map');
      } else {
        context.go('/onboarding/language');
      }
    } catch (e) {
      _timeoutTimer?.cancel();
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('❌ Google 로그인 오류 발생');
      debugPrint('에러 타입: ${e.runtimeType}');
      debugPrint('에러 메시지: $e');
      debugPrint('═══════════════════════════════════════════════════');
      
      // 웹 환경에서 리디렉션 예외는 정상적인 동작이므로 무시
      if (kIsWeb && (e.toString().contains('리디렉션') || 
                     e.toString().contains('Google 로그인 리디렉션'))) {
        debugPrint('✅ 웹 환경 리디렉션 예외 - 정상 동작입니다. 리디렉션 대기 중...');
        // 리디렉션이 곧 발생할 것이므로 로딩 상태 유지 (타임아웃은 위에서 설정됨)
        return;
      }
      
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // 사용자가 로그인을 취소한 경우는 에러 메시지를 표시하지 않음
      if (e.toString().contains('취소') || 
          e.toString().contains('cancel') ||
          e.toString().toLowerCase().contains('user cancelled')) {
        debugPrint('ℹ️ 사용자가 로그인을 취소했습니다.');
        return;
      }

      // 에러 메시지 표시
      debugPrint('⚠️ 에러 메시지를 사용자에게 표시합니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인에 실패했습니다. 다시 시도해주세요.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ResponsivePadding(
                child: Column(
                  children: [
                    // 로고를 중앙에 배치
                    Expanded(
                      child: Center(
                        child: _buildLogoPlaceholder(responsive),
                      ),
                    ),
                    // Google 로그인 버튼
                    _buildGoogleLoginButton(responsive, textTheme),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 10),
                    ),
                    // 영업 중 제보하기 버튼
                    _buildReportButton(responsive, textTheme),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 40),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(ResponsiveHelper responsive) {
    final logoSize = responsive.responsiveFontSize(mobileSize: 240);

    return Image.asset(
      "assets/designs/images/logo.png",
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
    );
  }

  Widget _buildGoogleLoginButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: _handleGoogleSignIn,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: responsive.responsivePadding(mobilePadding: 16),
          right: responsive.responsivePadding(mobilePadding: 16),
          top: responsive.responsivePadding(mobilePadding: 16),
          bottom: responsive.responsivePadding(mobilePadding: 16),
        ),
        decoration: BoxDecoration(
          color: AppColors.mainText.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Google 로고
            Image.asset(
              "assets/designs/images/Google_logo.png",
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            SizedBox(
              width: responsive.responsivePadding(mobilePadding: 8),
            ),
            Flexible(
              child: Text(
                "로그인",
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: () {
        context.go('/report/guide');
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: responsive.responsivePadding(mobilePadding: 16),
          right: responsive.responsivePadding(mobilePadding: 16),
          top: responsive.responsivePadding(mobilePadding: 16),
          bottom: responsive.responsivePadding(mobilePadding: 16),
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "영업 중 제보하기",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 16),
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

