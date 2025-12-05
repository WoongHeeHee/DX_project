import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  final GoogleSignIn _googleSignIn;

  AuthService(this._apiService)
      : _googleSignIn = GoogleSignIn(
          clientId: AppConfig.googleClientId,
          scopes: ['email', 'profile'],
          // 웹 환경에서 redirect URI 자동 처리
          hostedDomain: null,
        );

  // Google 로그인
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Google Client ID 확인
      if (AppConfig.googleClientId.isEmpty || 
          AppConfig.googleClientId.contains('your-google-client-id')) {
        throw Exception(
          'Google OAuth 클라이언트 ID가 설정되지 않았습니다.\n'
          'GOOGLE_OAUTH_SETUP.md 파일을 참고하여 설정해주세요.'
        );
      }

      // 웹에서는 GoogleSignIn이 자동으로 처리
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        throw Exception('Google 로그인이 취소되었습니다.');
      }

      // Google ID Token 가져오기
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('ID Token을 가져올 수 없습니다. Google OAuth 클라이언트 ID를 확인해주세요.');
      }

      // 백엔드에 인증 요청
      // 웹 환경에서는 redirect_uri가 필요 없지만, 백엔드 요구사항에 맞춰 전송
      final response = await _apiService.post(
        '/auth/google',
        data: {
          'code': idToken,
          'redirect_uri': AppConfig.googleRedirectUri, // 백엔드 요구사항에 맞춰 전송
        },
      );

      final tokenData = response.data as Map<String, dynamic>;
      final accessToken = tokenData['access_token'] as String;

      // API 서비스에 토큰 설정
      _apiService.setAccessToken(accessToken);

      // 사용자 정보 가져오기
      final userResponse = await _apiService.get('/auth/me');
      final userData = userResponse.data as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      return {
        'user': user,
        'accessToken': accessToken,
      };
    } catch (e) {
      // Google OAuth 관련 에러 처리
      final errorString = e.toString();
      if (errorString.contains('invalid_client') || 
          errorString.contains('OAuth client was not found') ||
          errorString.contains('client_id')) {
        throw Exception(
          'Google OAuth 클라이언트 ID가 올바르지 않습니다.\n'
          'GOOGLE_OAUTH_SETUP.md 파일을 참고하여 설정해주세요.'
        );
      }
      if (errorString.contains('redirect_uri_mismatch') ||
          errorString.contains('redirect_uri')) {
        throw Exception(
          '리디렉션 URI가 일치하지 않습니다.\n'
          'Google Cloud Console에서 승인된 JavaScript 원본과 리디렉션 URI를 확인하세요.\n'
          'FIX_REDIRECT_URI_MISMATCH.md 파일을 참고하세요.'
        );
      }
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _apiService.clearAccessToken();
    } catch (e) {
      rethrow;
    }
  }

  // 현재 사용자 정보 조회
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      final userData = response.data as Map<String, dynamic>;
      return UserModel.fromJson(userData);
    } catch (e) {
      rethrow;
    }
  }
}

