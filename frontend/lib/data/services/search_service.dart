import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/menu_models.dart';

/// 검색 관련 API 서비스
class SearchService {
  final ApiService _apiService;

  SearchService(this._apiService);

  /// 이미지 파일 직접 업로드하여 검색 (검색용 사진은 저장하지 않음)
  Future<List<SearchResult>> imageSearchUpload({
    required List<int> imageBytes,
    String? userText,
    double? lat,
    double? lng,
  }) async {
    // multipart/form-data로 이미지 파일 업로드
    final formDataMap = <String, dynamic>{
      'image': MultipartFile.fromBytes(
        imageBytes,
        filename: 'search_image.jpg',
      ),
    };
    if (userText != null && userText.isNotEmpty) {
      formDataMap['user_text'] = userText;
    }
    if (lat != null) {
      formDataMap['lat'] = lat.toString();
    }
    if (lng != null) {
      formDataMap['lng'] = lng.toString();
    }
    
    final formData = FormData.fromMap(formDataMap);

    final response = await _apiService.post(
      '/search/image-upload',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    final results = (response.data['results'] as List)
        .map((json) => SearchResult.fromJson(json as Map<String, dynamic>))
        .toList();
    return results;
  }

  /// 이미지 URL 또는 텍스트 검색 (기존 호환성용)
  Future<List<SearchResult>> imageSearch({
    String? imageUrl,
    String? userText,
    double? lat,
    double? lng,
  }) async {
    final data = <String, dynamic>{};
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (userText != null) data['user_text'] = userText;
    if (lat != null) data['lat'] = lat;
    if (lng != null) data['lng'] = lng;

    final response = await _apiService.post('/search/image', data: data);
    final results = (response.data['results'] as List)
        .map((json) => SearchResult.fromJson(json as Map<String, dynamic>))
        .toList();
    return results;
  }

  /// 메뉴 아이템 텍스트 검색
  Future<List<MenuItemModel>> searchMenuItems({
    required String query,
    String? marketId,
    int? spiceLevelMax,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{'q': query};
    if (marketId != null) queryParams['market_id'] = marketId;
    if (spiceLevelMax != null) queryParams['spice_level_max'] = spiceLevelMax;
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final response = await _apiService.get('/search/menu-items', queryParameters: queryParams);
    return (response.data as List)
        .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 인기 메뉴 조회
  Future<List<MenuItemModel>> getPopularMenus({
    String? marketId,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (marketId != null) queryParams['market_id'] = marketId;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _apiService.get('/search/popular-menus', queryParameters: queryParams);
    return (response.data as List)
        .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 트렌딩 키워드 조회
  Future<List<TrendingKeyword>> getTrendingKeywords({
    String? marketId,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (marketId != null) queryParams['market_id'] = marketId;
    if (limit != null) queryParams['limit'] = limit;

    final response = await _apiService.get('/search/trending-keywords', queryParameters: queryParams);
    return (response.data as List)
        .map((json) => TrendingKeyword.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

/// 검색 결과 모델
class SearchResult {
  final MenuItemModel menuItem;
  final double confidence;
  final List<ShopWithDistance> shopsNearby;

  SearchResult({
    required this.menuItem,
    required this.confidence,
    required this.shopsNearby,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      menuItem: MenuItemModel.fromJson(json['menu_item'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
      shopsNearby: (json['shops_nearby'] as List<dynamic>?)
              ?.map((e) => ShopWithDistance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 거리 정보가 포함된 가게 모델
class ShopWithDistance {
  final String id;
  final String marketId;
  final String name;
  final double lat;
  final double lng;
  final double distanceMeters;
  final String? status; // "green", "yellow", "red"

  ShopWithDistance({
    required this.id,
    required this.marketId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.distanceMeters,
    this.status,
  });

  factory ShopWithDistance.fromJson(Map<String, dynamic> json) {
    return ShopWithDistance(
      id: json['id'] as String,
      marketId: json['market_id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      distanceMeters: (json['distance_meters'] as num).toDouble(),
      status: json['status'] as String?,
    );
  }
}

/// 트렌딩 키워드 모델
class TrendingKeyword {
  final String keyword;
  final int count;

  TrendingKeyword({
    required this.keyword,
    required this.count,
  });

  factory TrendingKeyword.fromJson(Map<String, dynamic> json) {
    return TrendingKeyword(
      keyword: json['keyword'] as String,
      count: json['count'] as int,
    );
  }
}

