import 'api_service.dart';
import '../models/market_models.dart';

/// 시장 관련 API 서비스
class MarketService {
  final ApiService _apiService;

  MarketService(this._apiService);

  /// 시장 목록 조회
  Future<List<MarketModel>> getMarkets() async {
    final response = await _apiService.get('/markets');
    return (response.data as List)
        .map((json) => MarketModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 특정 시장 조회
  Future<MarketModel> getMarket(String marketId) async {
    final response = await _apiService.get('/markets/$marketId');
    return MarketModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// 시장 메뉴 아이템 목록
  Future<List<dynamic>> getMarketMenuItems(String marketId) async {
    final response = await _apiService.get('/markets/$marketId/menu-items');
    return response.data as List;
  }

  /// 시장 통계
  Future<MarketStatsModel> getMarketStats(String marketId) async {
    final response = await _apiService.get('/markets/$marketId/stats');
    return MarketStatsModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// 시장 부가정보 조회
  Future<MarketInfoModel> getMarketInfo(String marketId) async {
    final response = await _apiService.get('/markets/$marketId/info');
    return MarketInfoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// 시장 상태 조회
  Future<MarketStatusModel> getMarketStatus(String marketId, {String locale = 'ko'}) async {
    final response = await _apiService.get(
      '/markets/$marketId/status',
      queryParameters: {'locale': locale},
    );
    return MarketStatusModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// 시장의 특정 메뉴를 판매하는 가게 목록 조회
  Future<MarketShopsByMenuResponse> getShopsByMenu({
    required String marketId,
    required String menuName,
    double? lat,
    double? lng,
  }) async {
    final queryParams = <String, dynamic>{'menu_name': menuName};
    if (lat != null && lng != null) {
      queryParams['lat'] = lat;
      queryParams['lng'] = lng;
    }

    final response = await _apiService.get(
      '/markets/$marketId/shops/by-menu',
      queryParameters: queryParams,
    );
    return MarketShopsByMenuResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 시장 인기 키워드 조회
  Future<List<PopularKeyword>> getMarketTopKeywords(String marketId) async {
    final response = await _apiService.get('/markets/$marketId/top-keywords');
    return (response.data as List)
        .map((e) => PopularKeyword.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 시장 Must eat 메뉴 조회
  Future<List<dynamic>> getMarketMustEat(String marketId) async {
    final response = await _apiService.get('/markets/$marketId/must-eat');
    return response.data as List;
  }
}

