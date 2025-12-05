import 'api_service.dart';

class DiaryService {
  final ApiService _apiService;

  DiaryService(this._apiService);

  // 다이어리 생성
  Future<Map<String, dynamic>> createDiary({
    required String marketId,
    required List<String> keywords,
    List<String>? photoIds,
  }) async {
    try {
      final response = await _apiService.post(
        '/diary/',
        data: {
          'market_id': marketId,
          'keywords': keywords,
          'photo_ids': photoIds ?? [],
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // 좋아요 추가
  Future<void> addLike({
    required String menuItemId,
  }) async {
    try {
      await _apiService.post(
        '/diary/likes',
        data: {
          'menu_item_id': menuItemId,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // 좋아요 제거
  Future<void> removeLike({
    required String menuItemId,
  }) async {
    try {
      await _apiService.delete('/diary/likes/$menuItemId');
    } catch (e) {
      rethrow;
    }
  }
}

