import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../config/app_config.dart';

/// Google 인증 서비스
class GoogleAuthService {
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
      scopes: ['email', 'profile'],
    );
    _isInitialized = true;
  }

  /// Google 로그인 (id_token 반환)
  Future<String?> signIn() async {
    _initialize();
    
    if (_googleSignIn == null) {
      throw Exception('Google Client ID가 설정되지 않았습니다. .env 파일에 GOOGLE_CLIENT_ID를 설정해주세요.');
    }
    
    try {
      final GoogleSignInAccount? account = await _googleSignIn!.signIn();
      if (account == null) {
        return null; // 사용자가 로그인 취소
      }

      // id_token 가져오기
      final GoogleSignInAuthentication auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      throw Exception('Google 로그인 실패: $e');
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    _initialize();
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
  }

  /// 현재 로그인된 사용자 확인
  Future<bool> isSignedIn() async {
    _initialize();
    if (_googleSignIn == null) return false;
    return await _googleSignIn!.isSignedIn();
  }

  /// 현재 사용자 정보 가져오기
  Future<GoogleSignInAccount?> getCurrentUser() async {
    _initialize();
    if (_googleSignIn == null) return null;
    return await _googleSignIn!.currentUser;
  }
}

