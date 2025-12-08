import 'api_service.dart';
import '../models/auth_models.dart';
import 'google_auth_service.dart';

/// 인증 관련 API 서비스
class AuthService {
  final ApiService _apiService;
  final GoogleAuthService _googleAuthService;

  AuthService(this._apiService) : _googleAuthService = GoogleAuthService();

  /// Google 로그인 (id_token 방식)
  Future<TokenResponse> googleLogin() async {
    try {
      // Google에서 id_token 받기
      final idToken = await _googleAuthService.signIn();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google 로그인이 취소되었거나 id_token을 받을 수 없습니다.');
      }

      // 백엔드에 id_token 전달
      final response = await _apiService.post(
        '/auth/google',
        data: {
          'id_token': idToken,
        },
      );

      final tokenData = TokenResponse.fromJson(response.data);
      await _apiService.setAuthToken(tokenData.accessToken);
      return tokenData;
    } catch (e) {
      throw Exception('Google 로그인 처리 중 오류 발생: $e');
    }
  }

  /// Google 로그인 (id_token 직접 전달)
  Future<TokenResponse> googleLoginWithIdToken(String idToken) async {
    final response = await _apiService.post(
      '/auth/google',
      data: {
        'id_token': idToken,
      },
    );

    final tokenData = TokenResponse.fromJson(response.data);
    await _apiService.setAuthToken(tokenData.accessToken);

    return tokenData;
  }

  /// 현재 사용자 정보 조회
  Future<UserResponse> getCurrentUser() async {
    final response = await _apiService.get('/auth/me');
    return UserResponse.fromJson(response.data);
  }

  /// 토큰 갱신
  Future<TokenResponse> refreshToken() async {
    final response = await _apiService.post('/auth/refresh');
    final tokenData = TokenResponse.fromJson(response.data);
    await _apiService.setAuthToken(tokenData.accessToken);
    return tokenData;
  }

  /// 로그아웃
  Future<void> logout() async {
    await _apiService.logout();
  }
}

