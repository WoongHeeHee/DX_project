import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/utils/file_helper.dart';
import 'data/services/api_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/market_service.dart';
import 'data/services/menu_service.dart';
import 'data/services/photo_service.dart';
import 'data/services/recommendation_service.dart';
import 'data/services/search_service.dart';
import 'data/services/shop_service.dart';
import 'data/services/diary_service.dart';
import 'data/services/market_photo_service.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

import 'data/repositories/api_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  try {
    // Flutter 앱의 실제 경로 찾기
    String? envPath;

    if (kIsWeb) {
      // 웹에서는 assets에서 로드하거나 기본값 사용
      debugPrint('웹 환경: 기본값 사용');
    } else {
      // 모바일/데스크톱에서는 파일 헬퍼 사용
      envPath = await findEnvFile();
      if (envPath != null) {
        debugPrint('환경 변수 파일 발견: $envPath');
      }
    }

    if (envPath != null) {
      await dotenv.load(fileName: envPath);
      debugPrint('환경 변수 파일 로드 성공: $envPath');
      debugPrint('API_BASE_URL: ${dotenv.env['API_BASE_URL'] ?? '기본값 사용'}');
    } else {
      debugPrint('환경 변수 파일을 찾을 수 없습니다. 기본값을 사용합니다.');
      if (!kIsWeb) {
        debugPrint('모바일 환경: localhost 대신 실제 서버 IP 주소를 사용해야 합니다.');
        debugPrint('예: http://192.168.0.100:8000 (서버가 실행 중인 컴퓨터의 IP)');
      }
    }
  } catch (e) {
    debugPrint('환경 변수 파일 로드 중 오류 발생: $e');
    debugPrint('기본값을 사용합니다.');
  }

  // ApiRepository 초기화
  ApiRepository().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 서비스 인스턴스 생성
    final apiService = ApiService();
    final authService = AuthService(apiService);

    // 라우터 생성
    final router = AppRouter(authService: authService).router;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        Provider.value(value: apiService),
        Provider.value(value: authService),
        // 서비스들
        Provider.value(value: MarketService(apiService)),
        Provider.value(value: MenuService(apiService)),
        Provider.value(value: ShopService(apiService)),
        Provider.value(value: PhotoService(apiService)),
        Provider.value(value: RecommendationService(apiService)),
        Provider.value(value: SearchService(apiService)),
        Provider.value(value: MarketPhotoService(apiService)),
        Provider.value(value: DiaryService(apiService)),
      ],
      child: MaterialApp.router(
        title: '시장 탐방',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
          Locale('zh', 'CN'),
          Locale('ja', 'JP'),
        ],
        locale: const Locale('ko', 'KR'),
        routerConfig: router,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final maxWidth = 430.0;
          final clampedWidth = mediaQuery.size.width > maxWidth
              ? maxWidth
              : mediaQuery.size.width;
          final newMediaQuery = mediaQuery.copyWith(
            size: Size(clampedWidth, mediaQuery.size.height),
          );
          return MediaQuery(
            data: newMediaQuery,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
