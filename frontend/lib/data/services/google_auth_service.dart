import 'package:google_sign_in/google_sign_in.dart';
import '../../config/app_config.dart';

/// Google 인증 서비스
class GoogleAuthService {
  late GoogleSignIn _googleSignIn;

  GoogleAuthService() {
    _googleSignIn = GoogleSignIn(
      clientId: AppConfig.googleClientId,
      scopes: ['email', 'profile'],
    );
  }

  /// Google 로그인 (id_token 반환)
  Future<String?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
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
    await _googleSignIn.signOut();
  }

  /// 현재 로그인된 사용자 확인
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// 현재 사용자 정보 가져오기
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return await _googleSignIn.currentUser;
  }
}

