import '../../models/shop_model.dart';
import 'api_service.dart';

class ShopService {
  final ApiService _apiService;

  ShopService(this._apiService);

  // 주변 가게 조회
  Future<List<ShopModel>> getNearbyShops({
    required double lat,
    required double lng,
    double radiusMeters = 5.0,
    int limit = 5,
  }) async {
    try {
      final response = await _apiService.post(
        '/shops/nearby',
        data: {
          'lat': lat,
          'lng': lng,
          'radius_meters': radiusMeters,
          'limit': limit,
        },
      );
      // NearbyShopsResponse 형식: { success: bool, shops: List, total_count: int }
      final responseData = response.data as Map<String, dynamic>;
      final List<dynamic> shopsData = responseData['shops'] as List<dynamic>? ?? [];
      return shopsData.map((json) => ShopModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // 특정 가게 정보 조회
  Future<ShopModel> getShop(String shopId) async {
    try {
      final response = await _apiService.get('/shops/$shopId');
      return ShopModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // 가게 핀하기
  Future<void> pinShop(String shopId) async {
    try {
      await _apiService.post('/shops/$shopId/pin');
    } catch (e) {
      rethrow;
    }
  }

  // 가게 핀 해제
  Future<void> unpinShop(String shopId) async {
    try {
      await _apiService.delete('/shops/$shopId/pin');
    } catch (e) {
      rethrow;
    }
  }

  // 핀한 가게 목록 조회
  Future<List<ShopModel>> getPinnedShops({String? marketId}) async {
    try {
      final queryParams = marketId != null ? {'market_id': marketId} : null;
      final response = await _apiService.get('/shops/my-pins', queryParameters: queryParams);
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => ShopModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // 가게 영업 상태 업데이트
  Future<void> reportShopOpen(String shopId) async {
    try {
      await _apiService.post('/shops/$shopId/report-open');
    } catch (e) {
      rethrow;
    }
  }
}

