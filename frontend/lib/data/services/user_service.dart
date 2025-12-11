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
    
    // display_name과 korean_name은 null이어도 전송 (백엔드에서 처리)
    final data = <String, dynamic>{
      'country': country,
      'birth_yyyy_mm': birthYyyyMm,
      'spice_level': spiceLevel,
      'adventure': adventure,
      'korean_experience': koreanExperience,
    };
    
    // display_name과 korean_name 추가 (null이어도 포함)
    if (displayName != null) {
      data['display_name'] = displayName;
    }
    if (koreanName != null) {
      data['korean_name'] = koreanName;
    }
    if (locale != null) {
      data['locale'] = locale;
    }

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

  /// 시장 방문 기록 조회 (7일 이내, 미완성 다이어리)
  Future<MarketVisitResponse> getMarketVisits() async {
    final response = await _apiService.get('/users/market-visits');
    return MarketVisitResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// TOP 3 좋아요 음식 조회
  Future<List<TopFavoriteFood>> getTop3FavoriteFoods() async {
    final response = await _apiService.get('/users/top-3-favorite-foods');
    return (response.data as List)
        .map((json) => TopFavoriteFood.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 시장 기록 조회
  Future<List<MarketHistoryItem>> getMarketHistory() async {
    final response = await _apiService.get('/users/market-history');
    return (response.data as List)
        .map((json) => MarketHistoryItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 프로필 업데이트 (설정 화면용 - birth_yyyy_mm, locale 포함)
  Future<UserResponse> updateProfileSettings({
    String? koreanName,
    String? locale,
    String? birthYyyyMm,
    int? spiceLevel,
  }) async {
    final data = <String, dynamic>{};
    if (koreanName != null) data['korean_name'] = koreanName;
    if (locale != null) data['locale'] = locale;
    if (birthYyyyMm != null) data['birth_yyyy_mm'] = birthYyyyMm;
    if (spiceLevel != null) data['spice_level'] = spiceLevel;

    final response = await _apiService.put('/users/profile', data: data);
    final user = UserResponse.fromJson(response.data as Map<String, dynamic>);
    if (locale != null) {
      await setLocale(locale);
    }
    return user;
  }
}

/// 시장 기록 아이템 모델
class MarketHistoryItem {
  final String id;
  final String marketId;
  final String marketName;
  final int visitNumber;
  final String? visitedAt;

  MarketHistoryItem({
    required this.id,
    required this.marketId,
    required this.marketName,
    required this.visitNumber,
    this.visitedAt,
  });

  factory MarketHistoryItem.fromJson(Map<String, dynamic> json) {
    return MarketHistoryItem(
      id: json['id'] as String? ?? json['market_id'] as String,
      marketId: json['market_id'] as String,
      marketName: json['market_name'] as String,
      visitNumber: json['visit_number'] as int,
      visitedAt: json['visited_at'] as String?,
    );
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

/// 시장 방문 기록 응답 모델
class MarketVisitResponse {
  final bool hasRecentVisit;
  final String? marketName;
  final String? marketId;
  final String? diaryId;

  MarketVisitResponse({
    required this.hasRecentVisit,
    this.marketName,
    this.marketId,
    this.diaryId,
  });

  factory MarketVisitResponse.fromJson(Map<String, dynamic> json) {
    return MarketVisitResponse(
      hasRecentVisit: json['has_recent_visit'] as bool? ?? false,
      marketName: json['market_name'] as String?,
      marketId: json['market_id'] as String?,
      diaryId: json['diary_id'] as String?,
    );
  }
}

/// TOP 3 좋아요 음식 모델
class TopFavoriteFood {
  final String id;
  final String name;
  final String imageUrl;

  TopFavoriteFood({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory TopFavoriteFood.fromJson(Map<String, dynamic> json) {
    return TopFavoriteFood(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}

