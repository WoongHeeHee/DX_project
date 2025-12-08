import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../config/app_config.dart';
import 'google_auth_service_platform.dart';

/// Mobile/Desktop 전용 Google 인증 서비스
class GoogleAuthServiceMobile implements GoogleAuthServicePlatform {
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  void _initialize() {
    if (_isInitialized) return;
    
    final clientId = AppConfig.googleClientId;
    if (clientId.isEmpty) {
      debugPrint('경고: Google Client ID가 설정되지 않았습니다. .env 파일에 GOOGLE_CLIENT_ID를 설정해주세요.');
      return;
    }
    
    _googleSignIn = GoogleSignIn(
      clientId: clientId,
      scopes: ['email', 'profile', 'openid'],
    );
    _isInitialized = true;
  }

  /// Google 로그인 (id_token 반환)
  @override
  Future<String?> signIn() async {
    _initialize();
    
    if (_googleSignIn == null) {
      throw Exception('Google Client ID가 설정되지 않았습니다. .env 파일에 GOOGLE_CLIENT_ID를 설정해주세요.');
    }
    
    try {
      final GoogleSignInAccount? account = await _googleSignIn!.signIn();
      if (account == null) {
        debugPrint('Google 로그인: 사용자가 로그인을 취소했습니다.');
        return null;
      }

      debugPrint('Google 로그인: 계정 정보 가져오기 성공 - ${account.email}');
      
      // id_token 가져오기
      final GoogleSignInAuthentication auth = await account.authentication;
      
      if (auth.idToken == null) {
        debugPrint('경고: id_token이 null입니다.');
        throw Exception('Google 로그인: id_token을 받을 수 없습니다.');
      }
      
      debugPrint('Google 로그인: id_token 받기 성공');
      return auth.idToken;
    } catch (e, stackTrace) {
      debugPrint('Google 로그인 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      throw Exception('Google 로그인 실패: $e');
    }
  }

  /// 로그아웃
  @override
  Future<void> signOut() async {
    _initialize();
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
  }

  /// 현재 로그인된 사용자 확인
  @override
  Future<bool> isSignedIn() async {
    _initialize();
    if (_googleSignIn == null) return false;
    return await _googleSignIn!.isSignedIn();
  }

  /// 현재 사용자 정보 가져오기
  @override
  Future<GoogleSignInAccount?> getCurrentUser() async {
    _initialize();
    if (_googleSignIn == null) return null;
    return await _googleSignIn!.currentUser;
  }
}

/// Web 스텁 (모바일/데스크톱 환경에서는 사용되지 않음)
class GoogleAuthServiceWeb implements GoogleAuthServicePlatform {
  @override
  Future<String?> signIn() async {
    throw UnimplementedError('GoogleAuthServiceWeb은 웹 환경에서만 사용할 수 있습니다.');
  }

  @override
  Future<void> signOut() async {
    throw UnimplementedError('GoogleAuthServiceWeb은 웹 환경에서만 사용할 수 있습니다.');
  }

  @override
  Future<bool> isSignedIn() async {
    throw UnimplementedError('GoogleAuthServiceWeb은 웹 환경에서만 사용할 수 있습니다.');
  }

  @override
  Future<dynamic> getCurrentUser() async {
    throw UnimplementedError('GoogleAuthServiceWeb은 웹 환경에서만 사용할 수 있습니다.');
  }
  
  void dispose() {}
}
