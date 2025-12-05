import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 앱 설정 관리 클래스
class AppConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get googleRedirectUri => dotenv.env['GOOGLE_REDIRECT_URI'] ?? 'http://localhost';
  static String get kakaoMapApiKey => dotenv.env['KAKAO_MAP_API_KEY'] ?? '';
  static String get imageBaseUrl => dotenv.env['IMAGE_BASE_URL'] ?? '';
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
}

