import '../models/menu_model.dart';
import 'api_service.dart';

class MenuService {
  final ApiService _apiService;

  MenuService(this._apiService);

  // 메뉴 저장
  Future<void> saveMenu(String menuItemId) async {
    try {
      await _apiService.post('/menus/$menuItemId/save');
    } catch (e) {
      rethrow;
    }
  }

  // 메뉴 저장 해제
  Future<void> unsaveMenu(String menuItemId) async {
    try {
      await _apiService.delete('/menus/$menuItemId/save');
    } catch (e) {
      rethrow;
    }
  }

  // 저장한 메뉴 목록 조회
  Future<List<MenuModel>> getSavedMenus() async {
    try {
      final response = await _apiService.get('/menus/saved');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => MenuModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // 특정 메뉴 정보 조회
  Future<MenuModel> getMenu(String menuItemId) async {
    try {
      final response = await _apiService.get('/menus/$menuItemId');
      return MenuModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}

