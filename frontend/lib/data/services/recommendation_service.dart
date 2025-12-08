import 'api_service.dart';
import '../models/menu_models.dart';

/// 추천 관련 API 서비스
class RecommendationService {
  final ApiService _apiService;

  RecommendationService(this._apiService);

  /// 사용자 맞춤 추천
  Future<List<MenuItemModel>> getRecommendations({
    String? category,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (category != null) queryParams['category'] = category;

    final response = await _apiService.get('/recommendations/', queryParameters: queryParams);
    final recommendations = (response.data['recommendations'] as List)
        .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
    return recommendations;
  }

  /// 국적-나이별 트렌드
  Future<List<MenuItemModel>> getNationalityAgeTrend({
    required String country,
    required String birthYyyyMm,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{
      'country': country,
      'birth_yyyy_mm': birthYyyyMm,
    };
    if (limit != null) queryParams['limit'] = limit;

    final response = await _apiService.get(
      '/recommendations/nationality-age-trend',
      queryParameters: queryParams,
    );
    return (response.data as List)
        .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 트렌딩 메뉴
  Future<List<MenuItemModel>> getTrendingMenus({int limit = 10}) async {
    final response = await _apiService.get(
      '/recommendations/trending',
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 초보자 추천
  Future<List<MenuItemModel>> getForBeginners({int limit = 10}) async {
    final response = await _apiService.get(
      '/recommendations/for-beginners',
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

