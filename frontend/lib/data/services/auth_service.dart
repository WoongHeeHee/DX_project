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
  /// 웹 환경: GoogleAuthServiceWeb이 전체 페이지 리디렉션을 수행하므로 null 반환
  /// 모바일 환경: id_token을 받아서 백엔드에 전달
  Future<TokenResponse> googleLogin() async {
    try {
      debugPrint('[AuthService] Google 로그인 시작...');
      
      // Google에서 id_token 받기
      final idToken = await _googleAuthService.signIn();
      
      debugPrint('[AuthService] signIn() 완료, idToken: ${idToken != null ? "있음" : "null"}');
      
      // 웹 환경: 리디렉션이 발생했으므로 null 반환 (실제로는 여기까지 도달하지 않음)
      if (idToken == null || idToken.isEmpty) {
        if (kIsWeb) {
          // 웹 환경에서는 리디렉션이 발생했으므로 특별한 예외를 던짐
          // 이 예외는 login_screen에서 리디렉션 대기로 처리됨
          debugPrint('[AuthService] 웹 환경: 리디렉션 발생 - 예외 던짐');
          throw Exception('Google 로그인 리디렉션 중...');
        } else {
          // 모바일 환경에서는 사용자가 취소한 경우
          debugPrint('[AuthService] 모바일 환경: id_token 없음 - 사용자 취소로 간주');
          throw Exception('Google 로그인이 취소되었거나 id_token을 받을 수 없습니다.');
        }
      }

      debugPrint('[AuthService] 모바일 환경: id_token 받음, 백엔드에 전송...');
      
      // 모바일 환경: 백엔드에 id_token 전달
      final response = await _apiService.post(
        '/auth/google',
        data: {
          'id_token': idToken,
        },
      );

      final tokenData = TokenResponse.fromJson(response.data);
      await _apiService.setAuthToken(tokenData.accessToken);
      debugPrint('[AuthService] 모바일 환경: 로그인 성공');
      return tokenData;
    } catch (e) {
      debugPrint('[AuthService] Google 로그인 오류: $e');
      // 리디렉션 예외는 그대로 전달 (login_screen에서 처리)
      if (kIsWeb && e.toString().contains('리디렉션')) {
        rethrow;
      }
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
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
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
        throw Exception(
            '예상치 못한 응답 형식: ${response.data.runtimeType}, 데이터: ${response.data}');
      }

      debugPrint('파싱할 데이터: $responseData');
      debugPrint(
          'access_token 키 존재 여부: ${responseData.containsKey("access_token")}');
      debugPrint('모든 키: ${responseData.keys.toList()}');

      // 응답 데이터 검증
      if (!responseData.containsKey('access_token')) {
        debugPrint('⚠️ 백엔드 응답에 access_token이 없습니다!');
        debugPrint('응답 구조:');
        responseData.forEach((key, value) {
          final valueStr = value.toString();
          final preview = valueStr.length > 100
              ? '${valueStr.substring(0, 100)}...'
              : valueStr;
          debugPrint('  - $key (${value.runtimeType}): $preview');
        });
        throw Exception(
            '백엔드 응답에 access_token이 없습니다. 응답 키: ${responseData.keys.toList()}, 전체 응답: $responseData');
      }

      try {
        final tokenData = TokenResponse.fromJson(responseData);
        await _apiService.setAuthToken(tokenData.accessToken);
        debugPrint('✅ 토큰 파싱 및 저장 성공');
        return tokenData;
      } catch (e, stackTrace) {
        debugPrint('❌ TokenResponse.fromJson 실패: $e');
        debugPrint('스택 트레이스: $stackTrace');
        debugPrint('응답 데이터: $responseData');
        rethrow;
      }
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
