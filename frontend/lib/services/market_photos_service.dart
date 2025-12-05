import 'api_service.dart';

class MarketPhotosService {
  final ApiService _apiService;

  MarketPhotosService(this._apiService);

  // 시장 최근 사진 조회
  Future<List<Map<String, dynamic>>> getMarketRecentPhotos({
    required String marketId,
    String? category,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (category != null) queryParams['category'] = category;

      final response = await _apiService.get(
        '/market-photos/$marketId/recent',
        queryParameters: queryParams,
      );
      return (response.data as List<dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 시장 베스트셀링 메뉴
  Future<List<Map<String, dynamic>>> getMarketBestsellingMenus({
    required String marketId,
    int limit = 3,
  }) async {
    try {
      final response = await _apiService.get(
        '/market-photos/$marketId/bestselling',
        queryParameters: {'limit': limit},
      );
      return (response.data as List<dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 시장 가게 상태 조회
  Future<Map<String, dynamic>> getMarketShopStatuses(String marketId) async {
    try {
      final response = await _apiService.get('/market-photos/$marketId/shop-statuses');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // 시장 사진 위치 조회 (지도 핀용)
  Future<List<Map<String, dynamic>>> getMarketPhotoLocations({
    required String marketId,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/market-photos/$marketId/photo-locations',
        queryParameters: {'limit': limit},
      );
      return (response.data as List<dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}

