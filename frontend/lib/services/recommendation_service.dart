import '../models/menu_model.dart';
import 'api_service.dart';

class RecommendationService {
  final ApiService _apiService;

  RecommendationService(this._apiService);

  // 개인 맞춤 추천 메뉴
  Future<List<MenuModel>> getPersonalRecommendations({int limit = 3}) async {
    try {
      final response = await _apiService.get(
        '/recommendations/',
        queryParameters: {'limit': limit},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => MenuModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // 국적-나이별 트렌드 메뉴
  Future<List<MenuModel>> getTrendingMenus({
    String? country,
    String? birthYyyyMm,
    int limit = 3,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (country != null) queryParams['country'] = country;
      if (birthYyyyMm != null) queryParams['birth_yyyy_mm'] = birthYyyyMm;

      final response = await _apiService.get(
        '/recommendations/trending',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => MenuModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // 카테고리별 메뉴 조회
  Future<List<MenuModel>> getMenusByCategory(String category) async {
    try {
      final response = await _apiService.get(
        '/recommendations/',
        queryParameters: {'category': category},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => MenuModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

