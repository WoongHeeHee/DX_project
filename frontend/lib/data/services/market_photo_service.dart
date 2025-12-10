import 'api_service.dart';

/// 시장 사진 관련 API 서비스
class MarketPhotoService {
  final ApiService _apiService;

  MarketPhotoService(this._apiService);

  /// 시장 최근 사진 조회 (60분 이내)
  Future<MarketRecentPhotosResponse> getMarketRecentPhotos({
    required String marketId,
    String? category,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (category != null) queryParams['category'] = category;

    final response = await _apiService.get(
      '/market-photos/$marketId/recent-photos',
      queryParameters: queryParams,
    );
    return MarketRecentPhotosResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 시장 베스트셀링 메뉴 조회
  Future<List<MarketBestsellingItem>> getMarketBestselling({
    required String marketId,
    int limit = 3,
  }) async {
    final response = await _apiService.get(
      '/market-photos/$marketId/bestselling',
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((json) => MarketBestsellingItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 시장 가게 상태 조회
  Future<MarketShopsStatusResponse> getMarketShopsStatus({
    required String marketId,
    String locale = 'ko',
  }) async {
    final response = await _apiService.get(
      '/market-photos/$marketId/shops/status',
      queryParameters: {'locale': locale},
    );
    return MarketShopsStatusResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 시장 사진 위치 조회 (지도 핀용)
  Future<MarketPhotoLocationsResponse> getMarketPhotoLocations({
    required String marketId,
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      '/market-photos/$marketId/photos/locations',
      queryParameters: {'limit': limit},
    );
    return MarketPhotoLocationsResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

/// 시장 최근 사진 응답 모델
class MarketRecentPhotosResponse {
  final bool success;
  final List<MarketPhoto> photos;
  final int totalCount;

  MarketRecentPhotosResponse({
    required this.success,
    required this.photos,
    required this.totalCount,
  });

  factory MarketRecentPhotosResponse.fromJson(Map<String, dynamic> json) {
    return MarketRecentPhotosResponse(
      success: json['success'] as bool? ?? true,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => MarketPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['total_count'] as int? ?? 0,
    );
  }
}

/// 시장 사진 모델
class MarketPhoto {
  final String id;
  final String s3Key;
  final String? thumbnailS3Key;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double lat;
  final double lng;
  final DateTime takenAt;
  final String? menuItemId;
  final DateTime createdAt;
  final int minutesAgo;

  MarketPhoto({
    required this.id,
    required this.s3Key,
    this.thumbnailS3Key,
    this.imageUrl,
    this.thumbnailUrl,
    required this.lat,
    required this.lng,
    required this.takenAt,
    this.menuItemId,
    required this.createdAt,
    required this.minutesAgo,
  });

  factory MarketPhoto.fromJson(Map<String, dynamic> json) {
    return MarketPhoto(
      id: json['id'] as String,
      s3Key: json['s3_key'] as String,
      thumbnailS3Key: json['thumbnail_s3_key'] as String?,
      imageUrl: json['image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      takenAt: DateTime.parse(json['taken_at'] as String),
      menuItemId: json['menu_item_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      minutesAgo: json['minutes_ago'] as int? ?? 0,
    );
  }
}

/// 시장 베스트셀링 아이템 모델
class MarketBestsellingItem {
  final String menuItemId;
  final String menuItemName;
  final String? menuItemNameEn;
  final String? menuItemNameZh;
  final String? menuItemNameJa;
  final String? repImageUrl;
  final int orderCount;

  MarketBestsellingItem({
    required this.menuItemId,
    required this.menuItemName,
    this.menuItemNameEn,
    this.menuItemNameZh,
    this.menuItemNameJa,
    this.repImageUrl,
    required this.orderCount,
  });

  factory MarketBestsellingItem.fromJson(Map<String, dynamic> json) {
    return MarketBestsellingItem(
      menuItemId: json['menu_item_id'] as String,
      menuItemName: json['menu_item_name'] as String,
      menuItemNameEn: json['menu_item_name_en'] as String?,
      menuItemNameZh: json['menu_item_name_zh'] as String?,
      menuItemNameJa: json['menu_item_name_ja'] as String?,
      repImageUrl: json['rep_image_url'] as String?,
      orderCount: json['order_count'] as int? ?? 0,
    );
  }
}

/// 시장 가게 상태 응답 모델
class MarketShopsStatusResponse {
  final bool success;
  final List<ShopStatus> shops;
  final int totalCount;

  MarketShopsStatusResponse({
    required this.success,
    required this.shops,
    required this.totalCount,
  });

  factory MarketShopsStatusResponse.fromJson(Map<String, dynamic> json) {
    return MarketShopsStatusResponse(
      success: json['success'] as bool? ?? true,
      shops: (json['shops'] as List<dynamic>?)
              ?.map((e) => ShopStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['total_count'] as int? ?? 0,
    );
  }
}

/// 가게 상태 모델
class ShopStatus {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameZh;
  final String? nameJa;
  final double lat;
  final double lng;
  final String? repImageUrl;
  final String? openTime;
  final String? closeTime;
  final String? closedDays;
  final String? closedDaysEn;
  final String? closedDaysZh;
  final String? closedDaysJa;
  final DateTime? lastReportedOpenAt;
  final String status; // "green", "yellow", "red"

  ShopStatus({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameZh,
    this.nameJa,
    required this.lat,
    required this.lng,
    this.repImageUrl,
    this.openTime,
    this.closeTime,
    this.closedDays,
    this.closedDaysEn,
    this.closedDaysZh,
    this.closedDaysJa,
    this.lastReportedOpenAt,
    required this.status,
  });

  factory ShopStatus.fromJson(Map<String, dynamic> json) {
    return ShopStatus(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      nameZh: json['name_zh'] as String?,
      nameJa: json['name_ja'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      repImageUrl: json['rep_image_url'] as String?,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      closedDays: json['closed_days'] as String?,
      closedDaysEn: json['closed_days_en'] as String?,
      closedDaysZh: json['closed_days_zh'] as String?,
      closedDaysJa: json['closed_days_ja'] as String?,
      lastReportedOpenAt: json['last_reported_open_at'] != null
          ? DateTime.parse(json['last_reported_open_at'] as String)
          : null,
      status: json['status'] as String,
    );
  }
}

/// 시장 사진 위치 응답 모델
class MarketPhotoLocationsResponse {
  final bool success;
  final List<PhotoLocation> locations;

  MarketPhotoLocationsResponse({
    required this.success,
    required this.locations,
  });

  factory MarketPhotoLocationsResponse.fromJson(Map<String, dynamic> json) {
    return MarketPhotoLocationsResponse(
      success: json['success'] as bool? ?? true,
      locations: (json['locations'] as List<dynamic>?)
              ?.map((e) => PhotoLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 사진 위치 모델
class PhotoLocation {
  final double lat;
  final double lng;
  final String photoId;
  final DateTime takenAt;

  PhotoLocation({
    required this.lat,
    required this.lng,
    required this.photoId,
    required this.takenAt,
  });

  factory PhotoLocation.fromJson(Map<String, dynamic> json) {
    return PhotoLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      photoId: json['photo_id'] as String,
      takenAt: DateTime.parse(json['taken_at'] as String),
    );
  }
}

