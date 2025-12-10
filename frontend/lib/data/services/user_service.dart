import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/auth_models.dart';

/// 사용자 관련 API 서비스
class UserService {
  final ApiService _apiService;
  static const String _localeKey = 'user_locale';
  static const String _userIdKey = 'user_id';

  UserService(this._apiService);

  /// 현재 사용자 정보 조회
  Future<UserResponse> getCurrentUser() async {
    final response = await _apiService.get('/users/profile');
    final user = UserResponse.fromJson(response.data as Map<String, dynamic>);
    // locale 저장
    await setLocale(user.locale);
    await setUserId(user.id);
    return user;
  }

  /// 프로필 업데이트
  Future<UserResponse> updateProfile({
    String? displayName,
    String? koreanName,
    int? spiceLevel,
    String? locale,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (koreanName != null) data['korean_name'] = koreanName;
    if (spiceLevel != null) data['spice_level'] = spiceLevel;
    if (locale != null) data['locale'] = locale;

    final response = await _apiService.put('/users/profile', data: data);
    final user = UserResponse.fromJson(response.data as Map<String, dynamic>);
    if (locale != null) {
      await setLocale(locale);
    }
    return user;
  }

  /// 온보딩 완료
  Future<UserResponse> completeOnboarding({
    String? displayName,
    String? koreanName,
    required String country,
    required String birthYyyyMm,
    required int spiceLevel,
    required String adventure,
    required String koreanExperience,
    String? locale,
  }) async {
    // 디버그: 전달되는 데이터 확인
    debugPrint('=== completeOnboarding 호출 ===');
    debugPrint('displayName: $displayName');
    debugPrint('koreanName: $koreanName');
    
    final data = {
      if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
      if (koreanName != null && koreanName.isNotEmpty) 'korean_name': koreanName,
      'country': country,
      'birth_yyyy_mm': birthYyyyMm,
      'spice_level': spiceLevel,
      'adventure': adventure,
      'korean_experience': koreanExperience,
      if (locale != null) 'locale': locale,
    };

    debugPrint('전송할 data: $data');

    // 백엔드 API는 PUT /users/complete-onboarding을 사용
    final response = await _apiService.put('/users/complete-onboarding', data: data);
    final user = UserResponse.fromJson(response.data as Map<String, dynamic>);
    if (locale != null) {
      await setLocale(locale);
    }
    return user;
  }

  /// 한국 이름 생성
  Future<KoreanNameResponse> generateKoreanName(String inputName) async {
    try {
      final response = await _apiService.post(
        '/users/generate-korean-name',
        data: {'input_name': inputName},
      );
      
      // 응답 데이터 확인
      if (response.data == null) {
        throw Exception('서버 응답이 없습니다.');
      }
      
      final data = response.data as Map<String, dynamic>;
      
      // 응답 형식 확인 및 처리
      // API가 직접 korean_name과 english_pronunciation을 반환하는 경우
      if (data.containsKey('korean_name') && data.containsKey('english_pronunciation')) {
        return KoreanNameResponse.fromJson(data);
      }
      
      // API가 result 객체 안에 데이터를 반환하는 경우
      if (data.containsKey('result')) {
        final result = data['result'] as Map<String, dynamic>;
        return KoreanNameResponse.fromJson(result);
      }
      
      // API가 data 객체 안에 데이터를 반환하는 경우
      if (data.containsKey('data')) {
        final result = data['data'] as Map<String, dynamic>;
        return KoreanNameResponse.fromJson(result);
      }
      
      // 직접 반환
      return KoreanNameResponse.fromJson(data);
    } catch (e) {
      // 에러를 다시 throw하여 상위에서 처리할 수 있도록
      throw Exception('한국 이름 생성 실패: $e');
    }
  }

  /// Locale 저장
  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  /// Locale 가져오기
  Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'ko';
  }

  /// User ID 저장
  Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  /// User ID 가져오기
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
}

/// 한국 이름 생성 응답 모델
class KoreanNameResponse {
  final bool success;
  final String koreanName;
  final String englishPronunciation;

  KoreanNameResponse({
    required this.success,
    required this.koreanName,
    required this.englishPronunciation,
  });

  factory KoreanNameResponse.fromJson(Map<String, dynamic> json) {
    // 다양한 응답 형식 지원
    final koreanName = json['korean_name'] as String? ?? 
                       json['koreanName'] as String? ?? 
                       json['name'] as String? ?? 
                       '';
    
    final englishPronunciation = json['english_pronunciation'] as String? ?? 
                                 json['englishPronunciation'] as String? ?? 
                                 json['pronunciation'] as String? ?? 
                                 '';
    
    if (koreanName.isEmpty) {
      throw Exception('한국 이름이 응답에 포함되어 있지 않습니다.');
    }
    
    return KoreanNameResponse(
      success: json['success'] as bool? ?? true,
      koreanName: koreanName,
      englishPronunciation: englishPronunciation.isNotEmpty 
          ? englishPronunciation 
          : koreanName, // 영어 발음이 없으면 한국 이름을 사용
    );
  }
}

