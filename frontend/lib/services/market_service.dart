import '../models/market_model.dart';
import 'api_service.dart';

class MarketService {
  final ApiService _apiService;

  MarketService(this._apiService);

  // 모든 시장 목록 조회
  Future<List<MarketModel>> getMarkets() async {
    try {
      final response = await _apiService.get('/markets/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => MarketModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // 특정 시장 정보 조회
  Future<MarketModel> getMarket(String marketId) async {
    try {
      final response = await _apiService.get('/markets/$marketId');
      return MarketModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // 시장 통계 조회
  Future<Map<String, dynamic>> getMarketStats(String marketId) async {
    try {
      final response = await _apiService.get('/markets/$marketId/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}

