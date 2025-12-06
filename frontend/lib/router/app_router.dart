import 'package:go_router/go_router.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../features/onboarding/onboarding_language_screen.dart';
import '../features/onboarding/onboarding_name_screen.dart';
import '../features/onboarding/onboarding_loading_screen.dart';
import '../features/onboarding/onboarding_name_confirm_screen.dart';
import '../features/onboarding/onboarding_country_screen.dart';
import '../features/onboarding/onboarding_age_screen.dart';
import '../features/onboarding/onboarding_spicy_level_screen.dart';
import '../features/onboarding/onboarding_style_screen.dart';
import '../features/onboarding/onboarding_complete_screen.dart';
import '../screens/onboarding/onboarding_name_input_screen.dart';
import '../screens/onboarding/onboarding_name_generate_screen.dart';
import '../screens/onboarding/onboarding_main_1_screen.dart';
import '../screens/onboarding/onboarding_main_2_screen.dart';
import '../screens/report/report_guide_screen.dart';
import '../screens/report/report_camera_screen.dart';
import '../screens/report/report_shop_select_screen.dart';
import '../screens/report/report_complete_screen.dart';
import '../features/home/explore_screen.dart' as features;
import '../screens/map/map_market_select_screen.dart';
import '../screens/map/map_market_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/my/my_page_screen.dart';
import '../data/services/auth_service.dart';

class AppRouter {
  final AuthService authService;

  AppRouter({required this.authService});

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
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

      // 온보딩 (새로운 디자인)
      GoRoute(
        path: '/onboarding/language',
        builder: (context, state) => const OnboardingLanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding/name',
        builder: (context, state) => const OnboardingNameScreen(),
      ),
      GoRoute(
        path: '/onboarding/loading',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OnboardingLoadingScreen(
            inputName: extra?['inputName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/onboarding/name-confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OnboardingNameConfirmScreen(
            inputName: extra?['inputName'] as String?,
            koreanName: extra?['koreanName'] as String?,
            englishPronunciation: extra?['englishPronunciation'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/onboarding/country',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OnboardingCountryScreen(
            userName: extra?['userName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/onboarding/age',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OnboardingAgeScreen(
            userName: extra?['userName'] as String?,
            countryName: extra?['countryName'] as String?,
            countryId: extra?['countryId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/onboarding/spicy-level',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OnboardingSpicyLevelScreen(
            userName: extra?['userName'] as String?,
            countryName: extra?['countryName'] as String?,
            countryId: extra?['countryId'] as String?,
            birthYyyyMm: extra?['birthYyyyMm'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/onboarding/style',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OnboardingStyleScreen(
            userName: extra?['userName'] as String?,
            countryName: extra?['countryName'] as String?,
            countryId: extra?['countryId'] as String?,
            birthYyyyMm: extra?['birthYyyyMm'] as String?,
            spiceLevel: extra?['spiceLevel'] as int?,
            locale: extra?['locale'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/onboarding/complete',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OnboardingCompleteScreen(
            userName: extra?['userName'] as String?,
            countryName: extra?['countryName'] as String?,
          );
        },
      ),
      
      // 기존 온보딩 (레거시)
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
        builder: (context, state) => const features.ExploreScreen(),
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

