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

  // 내 다이어리 목록 조회
  Future<List<Map<String, dynamic>>> getMyDiaries({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _apiService.get(
        '/diary/my',
        queryParameters: queryParams,
      );
      return (response.data as List)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 시장별 사용자 사진 조회
  Future<List<MarketPhoto>> getMarketPhotos(String marketId) async {
    try {
      final response = await _apiService.get('/diary/market-photos/$marketId');
      return (response.data as List)
          .map((json) => MarketPhoto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}

/// 시장별 사진 모델
class MarketPhoto {
  final String id;
  final String photoUrl;
  final String recognizedMenuName;
  final String? menuItemId; // 좋아요 API 호출용
  final bool isLiked;

  MarketPhoto({
    required this.id,
    required this.photoUrl,
    required this.recognizedMenuName,
    this.menuItemId,
    required this.isLiked,
  });

  factory MarketPhoto.fromJson(Map<String, dynamic> json) {
    return MarketPhoto(
      id: json['id'] as String,
      photoUrl: json['photo_url'] as String? ?? '',
      recognizedMenuName: json['recognized_menu_name'] as String? ?? '',
      menuItemId: json['menu_item_id'] as String?,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }
}

