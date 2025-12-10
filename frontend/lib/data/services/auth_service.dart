import 'package:flutter/foundation.dart';
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
    try {
      final response = await _apiService.post(
        '/auth/google',
        data: {
          'id_token': idToken,
        },
      );

      // 응답 상태 코드 확인
      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception('서버 응답 오류: 상태 코드 ${response.statusCode}');
      }

      // 응답 데이터 로깅
      debugPrint('Google 로그인 응답 상태 코드: ${response.statusCode}');
      debugPrint('Google 로그인 응답 데이터 타입: ${response.data.runtimeType}');
      debugPrint('Google 로그인 응답 데이터: ${response.data}');
      
      if (response.data == null) {
        throw Exception('서버 응답이 비어있습니다.');
      }

      // response.data가 Map이 아닌 경우 처리
      Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String) {
        // JSON 문자열인 경우 파싱 시도
        throw Exception('응답이 JSON 문자열입니다. 서버 설정을 확인하세요: ${response.data}');
      } else {
        throw Exception('예상치 못한 응답 형식: ${response.data.runtimeType}, 데이터: ${response.data}');
      }

      debugPrint('파싱할 데이터: $responseData');
      debugPrint('access_token 키 존재 여부: ${responseData.containsKey("access_token")}');
      debugPrint('모든 키: ${responseData.keys.toList()}');
      
      final tokenData = TokenResponse.fromJson(responseData);
      await _apiService.setAuthToken(tokenData.accessToken);

      return tokenData;
    } catch (e, stackTrace) {
      debugPrint('Google 로그인 처리 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
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

