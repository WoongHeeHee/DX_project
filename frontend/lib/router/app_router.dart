import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding/onboarding_language_screen.dart';
import '../screens/onboarding/onboarding_name_input_screen.dart';
import '../screens/onboarding/onboarding_name_generate_screen.dart';
import '../screens/onboarding/onboarding_main_1_screen.dart';
import '../screens/onboarding/onboarding_main_2_screen.dart';
import '../screens/report/report_guide_screen.dart';
import '../screens/report/report_camera_screen.dart';
import '../screens/report/report_shop_select_screen.dart';
import '../screens/report/report_complete_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/map/map_market_select_screen.dart';
import '../screens/map/map_market_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/my/my_page_screen.dart';
import '../services/auth_service.dart';

class AppRouter {
  final AuthService authService;

  AppRouter({required this.authService});

  late final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      // 인증 관련
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 온보딩
      GoRoute(
        path: '/onboarding/language',
        builder: (context, state) => const OnboardingLanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding/name-input',
        builder: (context, state) => const OnboardingNameInputScreen(),
      ),
      GoRoute(
        path: '/onboarding/name-generate',
        builder: (context, state) => const OnboardingNameGenerateScreen(),
      ),
      GoRoute(
        path: '/onboarding/main-1',
        builder: (context, state) => const OnboardingMain1Screen(),
      ),
      GoRoute(
        path: '/onboarding/main-2',
        builder: (context, state) => const OnboardingMain2Screen(),
      ),

      // 가게 제보
      GoRoute(
        path: '/report/guide',
        builder: (context, state) => const ReportGuideScreen(),
      ),
      GoRoute(
        path: '/report/camera',
        builder: (context, state) => const ReportCameraScreen(),
      ),
      GoRoute(
        path: '/report/shop-select',
        builder: (context, state) => const ReportShopSelectScreen(),
      ),
      GoRoute(
        path: '/report/complete',
        builder: (context, state) => const ReportCompleteScreen(),
      ),

      // 메인 탭 (하단 네비게이션)
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapMarketSelectScreen(),
      ),
      GoRoute(
        path: '/map/market/:marketId',
        builder: (context, state) {
          final marketId = state.pathParameters['marketId']!;
          return MapMarketScreen(marketId: marketId);
        },
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/my',
        builder: (context, state) => const MyPageScreen(),
      ),
    ],
    redirect: (context, state) {
      // 인증 및 온보딩 체크는 각 화면에서 처리
      return null;
    },
  );
}

