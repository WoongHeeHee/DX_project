import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/api_repository.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../core/widgets/error_screen.dart';
import '../onboarding/onboarding_language_screen.dart';
import '../home/explore_screen.dart';
import '../report/report_guide_screen.dart';

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
      // Google 로그인 (id_token 받기)
      await _apiRepository.authService.googleLogin();
      
      // 사용자 정보 조회
      final user = await _apiRepository.authService.getCurrentUser();
      
      // locale 저장
      await _apiRepository.userService.setLocale(user.locale);
      
      if (mounted) {
        // 온보딩 완료 여부 확인 (country가 있으면 온보딩 완료)
        if (user.country != null && user.birthYyyyMm != null) {
          // 온보딩 완료 - 홈 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ExploreScreen()),
          );
        } else {
          // 온보딩 미완료 - 온보딩 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OnboardingLanguageScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AuthErrorScreen(
              onRetry: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleStoreReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportGuideScreen(),
      ),
    );
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
            // 화면 내 중앙 정렬을 위해 mainAxisAlignment를 spaceBetween 사용
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 상단 섹션: 로고 및 환영 메시지
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),

                  // 💡 NotoSansKR 26pt, Semi Bold (headlineLarge)
                  Text('환영합니다!', style: textTheme.headlineLarge),
                  const SizedBox(height: 8),

                  // 💡 NotoSansKR 14pt, Regular (bodyMedium)
                  Text(
                    '간편하게 구글로 로그인하고 Apex 시장의 최신 정보를 확인하세요.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),

              // 2. 하단 섹션: 버튼
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2-1. 구글 로그인 버튼 (Primary Action)
                  // 디자인 시스템에 정의된 elevatedButtonTheme 스타일이 자동 적용됩니다.
                  ElevatedButton.icon(
                    onPressed: () => _handleGoogleSignIn(context),
                    icon: Image.asset(
                      'assets/images/google_logo.png', // 실제 Google 로고 이미지 경로로 변경 필요
                      height: 24,
                    ),
                    label: Text(
                      'Google로 로그인',
                      // labelLarge 스타일이 ElevatedButtonTheme의 textStyle로 이미 정의되어 있음
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.white, // 흰색 텍스트 유지
                      ),
                    ),
                    // elevatedButtonTheme의 최소 높이(50)가 자동 적용됩니다.
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, // 테마의 primary 색상 사용
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2-2. 가게 제보하기 버튼 (Secondary Action)
                  // OutlinedButtonTheme을 활용하여 보조 버튼 스타일을 적용합니다.
                  OutlinedButton(
                    onPressed: () => _handleStoreReport(context),
                    // OutlinedButtonTheme에 정의된 테두리 스타일이 자동 적용됩니다.
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ), // primary 색상 테두리
                    ),
                    child: Text(
                      '가게 제보하기',
                      // OutlinedButtonTheme의 textStyle을 따라가지만, 색상은 primary로 변경
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40), // 하단 여백
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
