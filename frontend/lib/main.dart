import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/market_service.dart';
import 'services/menu_service.dart';
import 'services/shop_service.dart';
import 'services/photo_service.dart';
import 'services/recommendation_service.dart';
import 'services/search_service.dart';
import 'services/market_photos_service.dart';
import 'services/diary_service.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('환경 변수 파일을 찾을 수 없습니다. .env.example을 .env로 복사해주세요.');
  }

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
        Provider.value(value: MarketPhotosService(apiService)),
        Provider.value(value: DiaryService(apiService)),
      ],
      child: MaterialApp.router(
        title: '시장 탐방',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}

