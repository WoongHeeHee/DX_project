import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API 설정
  static String get apiBaseUrl {
    // 모바일 환경 감지
    final isMobile = !kIsWeb && !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS;
    
    // 모바일에서는 MOBILE_API_BASE_URL 우선 사용
    if (isMobile) {
      try {
        final mobileUrl = dotenv.env['MOBILE_API_BASE_URL'];
        if (mobileUrl != null && mobileUrl.isNotEmpty) {
          debugPrint('모바일 환경 - .env에서 MOBILE_API_BASE_URL 사용: $mobileUrl');
          return mobileUrl;
        }
      } catch (e) {
        debugPrint('dotenv에서 MOBILE_API_BASE_URL 읽기 실패: $e');
      }
      
      // .env에 없으면 하드코딩된 IP 사용 (fallback)
      debugPrint('모바일 환경 - 하드코딩된 서버 IP 사용: http://172.30.1.25:8000');
      return 'http://172.30.1.25:8000';
    }
    
    // 데스크톱/웹에서는 API_BASE_URL 사용
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        debugPrint('데스크톱/웹 환경 - .env에서 API_BASE_URL 사용: $envUrl');
        return envUrl;
      }
    } catch (e) {
      debugPrint('dotenv에서 API_BASE_URL 읽기 실패: $e');
    }
    
    debugPrint('기본값 사용: http://localhost:8000');
    return 'http://localhost:8000'; // 데스크톱/웹 기본값
  }
  static int get apiTimeout {
    try {
      return int.tryParse(dotenv.env['API_TIMEOUT'] ?? '60') ?? 60; // 모바일에서는 더 긴 타임아웃
    } catch (e) {
      return 60; // 기본값 60초
    }
  }

  // Google OAuth
  static String get googleClientId {
    try {
      final clientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
      // 개발 환경에서 플레이스홀더 값 체크
      if (clientId.isEmpty || clientId.contains('your-google-client-id')) {
        return '';
      }
      return clientId;
    } catch (e) {
      return '';
    }
  }
  
  static String get googleRedirectUri {
    try {
      return dotenv.env['GOOGLE_REDIRECT_URI'] ?? 'http://localhost:8080/auth/callback';
    } catch (e) {
      return 'http://localhost:8080/auth/callback';
    }
  }

  // 지도 API
  static String get kakaoMapApiKey {
    try {
      return dotenv.env['KAKAO_MAP_API_KEY'] ?? '';
    } catch (e) {
      return '';
    }
  }
  
  static String get naverMapClientId {
    try {
      return dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
    } catch (e) {
      return '';
    }
  }
  
  static String get naverMapClientSecret {
    try {
      return dotenv.env['NAVER_MAP_CLIENT_SECRET'] ?? '';
    } catch (e) {
      return '';
    }
  }

  // 환경
  static String get environment {
    try {
      return dotenv.env['ENVIRONMENT'] ?? 'development';
    } catch (e) {
      return 'development';
    }
  }
  
  static bool get isDevelopment => environment == 'development';

  // 이미지 서버
  static String get imageBaseUrl {
    try {
      return dotenv.env['IMAGE_BASE_URL'] ?? 'http://localhost:9000/market-explorer-photos';
    } catch (e) {
      return 'http://localhost:9000/market-explorer-photos';
    }
  }

  // 이미지 URL 생성 헬퍼
  static String getImageUrl(String? s3Key, {bool thumbnail = false}) {
    if (s3Key == null || s3Key.isEmpty) return '';
    String key = thumbnail && s3Key.contains('.jpg') 
        ? s3Key.replaceFirst('.jpg', '_thumb.jpg') 
        : s3Key;
    return '$imageBaseUrl/$key';
  }
}

