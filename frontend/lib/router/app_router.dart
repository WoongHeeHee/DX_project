import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html if (dart.library.html) 'dart:html';
import '../features/auth/login_screen.dart';
import '../features/auth/auth_callback_screen.dart';
import '../features/onboarding/onboarding_language_screen.dart';
import '../features/onboarding/onboarding_name_screen.dart';
import '../features/onboarding/onboarding_loading_screen.dart';
import '../features/onboarding/onboarding_name_confirm_screen.dart';
import '../features/onboarding/onboarding_country_screen.dart';
import '../features/onboarding/onboarding_age_screen.dart';
import '../features/onboarding/onboarding_spicy_level_screen.dart';
import '../features/onboarding/onboarding_style_screen.dart';
import '../features/onboarding/onboarding_complete_screen.dart';
import '../features/home/explore_screen.dart' as features;
import '../features/home/food_detail_screen.dart';
import '../features/home/market_detail_screen.dart';
import '../features/home/models/food_model.dart';
import '../features/home/models/market_model.dart';
import '../features/map/map_screen.dart';
import '../features/map/market_map_detail_screen.dart';
import '../features/map/store_list_screen.dart';
import '../features/search/search_screen.dart';
import '../features/search/image_search_screen.dart';
import '../features/search/text_search_screen.dart';
import '../features/search/search_result_screen.dart';
import '../features/search/search_error_screen.dart';
import '../features/search/models/search_result_model.dart';
import '../features/camera/camera_preview_screen.dart';
import '../features/camera/camera_success_screen.dart';
import '../features/camera/camera_take_photo_screen.dart';
import '../features/report/report_guide_screen.dart';
import '../features/report/report_camera_screen.dart';
import '../features/report/report_loading_screen.dart';
import '../features/report/report_shop_select_screen.dart';
import '../features/report/report_complete_screen.dart';
import '../data/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class AppRouter {
  final AuthService authService;

  AppRouter({required this.authService});

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // 인증 관련
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Google OAuth 리디렉션 콜백 처리
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) {
          // GoRouter의 state.uri에서 query parameter와 fragment 모두 전달
          // AuthCallbackScreen에서 URL에서 id_token을 추출하여 자동 로그인 처리
          return AuthCallbackScreen(uri: state.uri);
        },
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
          final inputName = extra?['inputName'] as String? ?? '';
          return OnboardingLoadingScreen(
            inputName: inputName,
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
        path: '/report/loading',
        builder: (context, state) {
          return const ReportLoadingScreen();
        },
      ),
      GoRoute(
        path: '/report/shop-select',
        builder: (context, state) {
          return const ReportShopSelectScreen();
        },
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
        path: '/explore/food/:foodId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final food = extra?['food'] as FoodModel?;
          if (food == null) {
            throw Exception('FoodModel이 필요합니다.');
          }
          return FoodDetailScreen(food: food);
        },
      ),
      GoRoute(
        path: '/explore/market/:marketId',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final market = extra?['market'] as MarketModel?;
          if (market == null) {
            throw Exception('MarketModel이 필요합니다.');
          }
          return MarketDetailScreen(market: market);
        },
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/map/market/:marketId/detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final market = extra?['market'] as MarketModel?;
          if (market == null) {
            throw Exception('MarketModel이 필요합니다.');
          }
          return MarketMapDetailScreen(market: market);
        },
      ),
      GoRoute(
        path: '/map/market/:marketId/store-list',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final market = extra?['market'] as MarketModel?;
          final menuName = extra?['menuName'] as String?;
          if (market == null || menuName == null) {
            throw Exception('MarketModel과 menuName이 필요합니다.');
          }
          return StoreListScreen(market: market, menuName: menuName);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/search/image',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialImage = extra?['initialImage'] as XFile?;
          return ImageSearchScreen(initialImage: initialImage);
        },
      ),
      GoRoute(
        path: '/search/text',
        builder: (context, state) => const TextSearchScreen(),
      ),
      GoRoute(
        path: '/search/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final result = extra?['result'] as SearchResultModel?;
          if (result == null) {
            throw Exception('SearchResultModel이 필요합니다.');
          }
          return SearchResultScreen(result: result);
        },
      ),
      GoRoute(
        path: '/search/error',
        builder: (context, state) => const SearchErrorScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final returnPath = extra?['returnPath'] as String?;
          return CameraPreviewScreen(returnPath: returnPath);
        },
      ),
      GoRoute(
        path: '/camera/preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final returnPath = extra?['returnPath'] as String?;
          return CameraPreviewScreen(returnPath: returnPath);
        },
      ),
      GoRoute(
        path: '/camera/take-photo',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final returnPath = extra?['returnPath'] as String?;
          return CameraTakePhotoScreen(returnPath: returnPath);
        },
      ),
      GoRoute(
        path: '/camera/success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final returnPath = extra?['returnPath'] as String?;
          return CameraSuccessScreen(returnPath: returnPath);
        },
      ),
    ],
    redirect: (context, state) {
      // /auth/callback 경로는 query parameter나 fragment와 함께 와도 그대로 통과
      // (AuthCallbackScreen에서 id_token을 추출하여 처리)
      if (state.uri.path == '/auth/callback') {
        return null;
      }

      // 인증 및 온보딩 체크는 각 화면에서 처리
      return null;
    },

    // 에러 핸들러: 라우트를 찾을 수 없는 경우 처리
    errorBuilder: (context, state) {
      debugPrint('=== GoRouter 에러: 경로를 찾을 수 없음 ===');
      debugPrint('전체 URI: ${state.uri}');
      debugPrint('Path: ${state.uri.path}');
      debugPrint('Query: ${state.uri.query}');
      debugPrint(
          'Fragment: ${state.uri.fragment.isNotEmpty ? state.uri.fragment.substring(0, 100) + "..." : "없음"}');

      // 웹 환경에서 window.location을 직접 확인 (GoRouter가 프래그먼트를 제대로 파싱하지 못할 수 있음)
      if (kIsWeb) {
        try {
          final windowLocation = html.window.location;
          final windowHash = windowLocation.hash;

          debugPrint('window.location.href: ${windowLocation.href}');
          debugPrint(
              'window.location.hash: ${windowHash.isNotEmpty ? windowHash.substring(0, 100) + "..." : "없음"}');

          // 프래그먼트에 id_token이 있는 경우 (정상적인 OAuth 응답)
          if (windowHash.isNotEmpty && windowHash.contains('id_token=')) {
            debugPrint(
                '✅ window.location.hash에서 id_token 발견, /auth/callback으로 리디렉션');
            // 프래그먼트를 포함한 올바른 URI로 리디렉션
            final callbackUri = Uri(
              path: '/auth/callback',
              fragment: windowHash.startsWith('#')
                  ? windowHash.substring(1)
                  : windowHash,
            );
            return AuthCallbackScreen(uri: callbackUri);
          }
        } catch (e) {
          debugPrint('window.location 확인 실패: $e');
        }
      }

      // state.uri의 프래그먼트에 id_token이 있는 경우
      if (state.uri.fragment.isNotEmpty &&
          state.uri.fragment.contains('id_token=')) {
        debugPrint('✅ state.uri.fragment에서 id_token 발견, /auth/callback으로 리디렉션');
        final callbackUri = Uri(
          path: '/auth/callback',
          fragment: state.uri.fragment,
        );
        return AuthCallbackScreen(uri: callbackUri);
      }

      // id_token이 경로에 포함된 경우 (잘못된 redirect) - Google Cloud Console 설정 문제
      if (state.uri.path.contains('id_token') ||
          state.uri.path.startsWith('id_token')) {
        debugPrint('⚠️ 경고: id_token이 경로로 인식되었습니다.');
        debugPrint('⚠️ Google Cloud Console의 redirect URI 설정을 확인하세요.');
        debugPrint('⚠️ 올바른 설정: https://sijanggo.com/auth/callback');

        // id_token을 추출하여 /auth/callback으로 리디렉션 시도
        final pathParts = state.uri.path.split('id_token=');
        if (pathParts.length > 1) {
          final idTokenPart = pathParts[1].split('&')[0].split('#')[0];
          debugPrint(
              '⚠️ 경로에서 id_token 추출 시도: ${idTokenPart.substring(0, 20)}...');
          return AuthCallbackScreen(
              uri: Uri.parse('/auth/callback?id_token=$idTokenPart'));
        }
      }

      // 기본 에러 화면
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('페이지를 찾을 수 없습니다',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('경로: ${state.uri.path}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('로그인 화면으로 돌아가기'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
