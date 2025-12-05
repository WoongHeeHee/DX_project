import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
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
    required String country,
    required String birthYyyyMm,
    required int spiceLevel,
    required String adventure,
    required String koreanExperience,
    String? locale,
  }) async {
    final data = {
      'country': country,
      'birth_yyyy_mm': birthYyyyMm,
      'spice_level': spiceLevel,
      'adventure': adventure,
      'korean_experience': koreanExperience,
      if (locale != null) 'locale': locale,
    };

    final response = await _apiService.post('/users/onboarding', data: data);
    final user = UserResponse.fromJson(response.data as Map<String, dynamic>);
    if (locale != null) {
      await setLocale(locale);
    }
    return user;
  }

  /// 한국 이름 생성
  Future<KoreanNameResponse> generateKoreanName(String inputName) async {
    final response = await _apiService.post(
      '/users/generate-korean-name',
      data: {'input_name': inputName},
    );
    return KoreanNameResponse.fromJson(response.data as Map<String, dynamic>);
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
    return KoreanNameResponse(
      success: json['success'] as bool? ?? true,
      koreanName: json['korean_name'] as String,
      englishPronunciation: json['english_pronunciation'] as String,
    );
  }
}

