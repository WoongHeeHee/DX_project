import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API 설정
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;

  // Google OAuth
  static String get googleClientId {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
    // 개발 환경에서 플레이스홀더 값 체크
    if (clientId.isEmpty || clientId.contains('your-google-client-id')) {
      return '';
    }
    return clientId;
  }
  static String get googleRedirectUri => dotenv.env['GOOGLE_REDIRECT_URI'] ?? 'http://localhost:8080/auth/callback';

  // 지도 API
  static String get kakaoMapApiKey => dotenv.env['KAKAO_MAP_API_KEY'] ?? '';
  static String get naverMapClientId => dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
  static String get naverMapClientSecret => dotenv.env['NAVER_MAP_CLIENT_SECRET'] ?? '';

  // 환경
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isDevelopment => environment == 'development';

  // 이미지 서버
  static String get imageBaseUrl => dotenv.env['IMAGE_BASE_URL'] ?? 'http://localhost:9000/market-explorer-photos';

  // 이미지 URL 생성 헬퍼
  static String getImageUrl(String? s3Key, {bool thumbnail = false}) {
    if (s3Key == null || s3Key.isEmpty) return '';
    String key = thumbnail && s3Key.contains('.jpg') 
        ? s3Key.replaceFirst('.jpg', '_thumb.jpg') 
        : s3Key;
    return '$imageBaseUrl/$key';
  }
}

