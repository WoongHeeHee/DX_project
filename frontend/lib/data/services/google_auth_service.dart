import 'package:flutter/foundation.dart';
import 'google_auth_service_platform.dart';
import 'google_auth_service_stub.dart'
    if (dart.library.html) 'google_auth_service_web.dart'
    if (dart.library.io) 'google_auth_service_mobile.dart';

/// 플랫폼별 Google 인증 서비스
/// 웹: Google Identity Services (GIS) 기반
/// 모바일/데스크톱: google_sign_in 패키지 기반
class GoogleAuthService {
  final GoogleAuthServicePlatform _platformService;
  
  GoogleAuthService() : _platformService = _createPlatformService();
  
  static GoogleAuthServicePlatform _createPlatformService() {
    if (kIsWeb) {
      return GoogleAuthServiceWeb();
    } else {
      return GoogleAuthServiceMobile();
    }
  }

  /// Google 로그인 (id_token 반환)
  Future<String?> signIn() async {
    return await _platformService.signIn();
  }

  /// 로그아웃
  Future<void> signOut() async {
    return await _platformService.signOut();
  }

  /// 현재 로그인된 사용자 확인
  Future<bool> isSignedIn() async {
    return await _platformService.isSignedIn();
  }

  /// 현재 사용자 정보 가져오기
  Future<dynamic> getCurrentUser() async {
    return await _platformService.getCurrentUser();
  }
  
  /// Web 전용: dispose (리소스 정리)
  void dispose() {
    if (kIsWeb && _platformService is GoogleAuthServiceWeb) {
      (_platformService as GoogleAuthServiceWeb).dispose();
    }
  }
}
