import '../services/api_service.dart';
import '../models/menu_models.dart';

/// 메뉴 관련 API 서비스
class MenuService {
  final ApiService _apiService;

  MenuService(this._apiService);

  /// 메뉴 아이템 목록 조회
  Future<List<MenuItemModel>> getMenuItems({
    String? marketId,
    String? category,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{};
    if (marketId != null) queryParams['market_id'] = marketId;
    if (category != null) queryParams['category'] = category;
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final response = await _apiService.get('/menus', queryParameters: queryParams);
    return (response.data as List)
        .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 특정 메뉴 아이템 조회 (상세 정보)
  Future<MenuItemDetailModel> getMenuItem(String menuItemId) async {
    final response = await _apiService.get('/menus/$menuItemId');
    return MenuItemDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// 메뉴 찜하기
  Future<void> saveMenuItem(String menuItemId) async {
    await _apiService.post('/menus/$menuItemId/save');
  }

  /// 메뉴 찜 해제
  Future<void> unsaveMenuItem(String menuItemId) async {
    await _apiService.delete('/menus/$menuItemId/save');
  }

  /// 내가 찜한 메뉴 목록
  Future<List<MenuItemModel>> getSavedMenuItems({
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final response = await _apiService.get('/menus/saved', queryParameters: queryParams);
    return (response.data as List)
        .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

