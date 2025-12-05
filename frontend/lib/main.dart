import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
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
      // 모바일/데스크톱에서는 여러 경로 시도
      final currentDir = Directory.current.path;
      final appDocDir = await getApplicationDocumentsDirectory();

      final possiblePaths = [
        // 상대 경로
        '.env',
        'frontend/.env',
        // 절대 경로
        path.join(currentDir, '.env'),
        path.join(currentDir, 'frontend', '.env'),
        // 앱 문서 디렉토리 기반
        path.join(appDocDir.path, '..', '..', 'frontend', '.env'),
        path.join(appDocDir.path, '..', 'frontend', '.env'),
      ];

      for (final tryPath in possiblePaths) {
        try {
          final file = File(tryPath);
          if (await file.exists()) {
            envPath = tryPath;
            debugPrint('환경 변수 파일 발견: $tryPath');
            break;
          }
        } catch (e) {
          continue;
        }
      }
    }

    if (envPath != null) {
      await dotenv.load(fileName: envPath);
      debugPrint('환경 변수 파일 로드 성공: $envPath');
      debugPrint('API_BASE_URL: ${dotenv.env['API_BASE_URL'] ?? '기본값 사용'}');
    } else {
      debugPrint('환경 변수 파일을 찾을 수 없습니다. 기본값을 사용합니다.');
      // 기본값 설정 (모바일에서는 localhost 대신 실제 서버 IP 필요)
      if (!kIsWeb &&
          !Platform.isWindows &&
          !Platform.isLinux &&
          !Platform.isMacOS) {
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
      ),
    );
  }
}
