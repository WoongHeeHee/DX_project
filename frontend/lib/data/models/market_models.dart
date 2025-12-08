/// 시장 모델
class MarketModel {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameZh;
  final String? nameJa;
  final String? description;
  final String? descriptionEn;
  final String? descriptionZh;
  final String? descriptionJa;
  final String? silhouetteUrl;
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  MarketModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameZh,
    this.nameJa,
    this.description,
    this.descriptionEn,
    this.descriptionZh,
    this.descriptionJa,
    this.silhouetteUrl,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      nameZh: json['name_zh'] as String?,
      nameJa: json['name_ja'] as String?,
      description: json['description'] as String?,
      descriptionEn: json['description_en'] as String?,
      descriptionZh: json['description_zh'] as String?,
      descriptionJa: json['description_ja'] as String?,
      silhouetteUrl: json['silhouette_url'] as String?,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// locale에 맞는 이름 반환
  String getNameByLocale(String locale) {
    switch (locale) {
      case 'en':
        return nameEn ?? name;
      case 'zh':
        return nameZh ?? name;
      case 'ja':
        return nameJa ?? name;
      default:
        return name;
    }
  }

  /// locale에 맞는 설명 반환
  String? getDescriptionByLocale(String locale) {
    switch (locale) {
      case 'en':
        return descriptionEn ?? description;
      case 'zh':
        return descriptionZh ?? description;
      case 'ja':
        return descriptionJa ?? description;
      default:
        return description;
    }
  }
}

/// 시장 부가정보 모델
class MarketInfoModel {
  final String marketInfoId;
  final String marketId;
  final String? address;
  final String? addressEn;
  final String? addressZh;
  final String? addressJa;
  final String? transport;
  final String? transportEn;
  final String? transportZh;
  final String? transportJa;
  final String? parking;
  final String? parkingEn;
  final String? parkingZh;
  final String? parkingJa;
  final String? restroom;
  final String? restroomEn;
  final String? restroomZh;
  final String? restroomJa;
  final String? openTime;
  final String? closeTime;
  final String? closedDays;
  final String? closedDaysEn;
  final String? closedDaysZh;
  final String? closedDaysJa;

  MarketInfoModel({
    required this.marketInfoId,
    required this.marketId,
    this.address,
    this.addressEn,
    this.addressZh,
    this.addressJa,
    this.transport,
    this.transportEn,
    this.transportZh,
    this.transportJa,
    this.parking,
    this.parkingEn,
    this.parkingZh,
    this.parkingJa,
    this.restroom,
    this.restroomEn,
    this.restroomZh,
    this.restroomJa,
    this.openTime,
    this.closeTime,
    this.closedDays,
    this.closedDaysEn,
    this.closedDaysZh,
    this.closedDaysJa,
  });

  factory MarketInfoModel.fromJson(Map<String, dynamic> json) {
    return MarketInfoModel(
      marketInfoId: json['market_info_id'] as String,
      marketId: json['market_id'] as String,
      address: json['address'] as String?,
      addressEn: json['address_en'] as String?,
      addressZh: json['address_zh'] as String?,
      addressJa: json['address_ja'] as String?,
      transport: json['transport'] as String?,
      transportEn: json['transport_en'] as String?,
      transportZh: json['transport_zh'] as String?,
      transportJa: json['transport_ja'] as String?,
      parking: json['parking'] as String?,
      parkingEn: json['parking_en'] as String?,
      parkingZh: json['parking_zh'] as String?,
      parkingJa: json['parking_ja'] as String?,
      restroom: json['restroom'] as String?,
      restroomEn: json['restroom_en'] as String?,
      restroomZh: json['restroom_zh'] as String?,
      restroomJa: json['restroom_ja'] as String?,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      closedDays: json['closed_days'] as String?,
      closedDaysEn: json['closed_days_en'] as String?,
      closedDaysZh: json['closed_days_zh'] as String?,
      closedDaysJa: json['closed_days_ja'] as String?,
    );
  }

  /// locale에 맞는 주소 반환
  String? getAddressByLocale(String locale) {
    switch (locale) {
      case 'en':
        return addressEn ?? address;
      case 'zh':
        return addressZh ?? address;
      case 'ja':
        return addressJa ?? address;
      default:
        return address;
    }
  }

  /// locale에 맞는 교통 정보 반환
  String? getTransportByLocale(String locale) {
    switch (locale) {
      case 'en':
        return transportEn ?? transport;
      case 'zh':
        return transportZh ?? transport;
      case 'ja':
        return transportJa ?? transport;
      default:
        return transport;
    }
  }

  /// locale에 맞는 주차 정보 반환
  String? getParkingByLocale(String locale) {
    switch (locale) {
      case 'en':
        return parkingEn ?? parking;
      case 'zh':
        return parkingZh ?? parking;
      case 'ja':
        return parkingJa ?? parking;
      default:
        return parking;
    }
  }

  /// locale에 맞는 화장실 정보 반환
  String? getRestroomByLocale(String locale) {
    switch (locale) {
      case 'en':
        return restroomEn ?? restroom;
      case 'zh':
        return restroomZh ?? restroom;
      case 'ja':
        return restroomJa ?? restroom;
      default:
        return restroom;
    }
  }

  /// locale에 맞는 휴무일 반환
  String? getClosedDaysByLocale(String locale) {
    switch (locale) {
      case 'en':
        return closedDaysEn ?? closedDays;
      case 'zh':
        return closedDaysZh ?? closedDays;
      case 'ja':
        return closedDaysJa ?? closedDays;
      default:
        return closedDays;
    }
  }
}

/// 시장 통계 모델
class MarketStatsModel {
  final int totalShops;
  final int totalMenuItems;
  final int recentPhotosCount;
  final List<PopularKeyword> popularKeywords;

  MarketStatsModel({
    required this.totalShops,
    required this.totalMenuItems,
    required this.recentPhotosCount,
    required this.popularKeywords,
  });

  factory MarketStatsModel.fromJson(Map<String, dynamic> json) {
    return MarketStatsModel(
      totalShops: json['total_shops'] as int? ?? 0,
      totalMenuItems: json['total_menu_items'] as int? ?? 0,
      recentPhotosCount: json['recent_photos_count'] as int? ?? 0,
      popularKeywords: (json['popular_keywords'] as List<dynamic>?)
              ?.map((e) => PopularKeyword.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 인기 키워드 모델
class PopularKeyword {
  final String keyword;
  final int count;

  PopularKeyword({
    required this.keyword,
    required this.count,
  });

  factory PopularKeyword.fromJson(Map<String, dynamic> json) {
    return PopularKeyword(
      keyword: json['keyword'] as String,
      count: json['count'] as int,
    );
  }
}

/// 시장 상태 모델
class MarketStatusModel {
  final String status; // "green", "yellow", "red"
  final int totalShops;
  final int openShops;
  final int suspiciousShops;
  final int closedShops;

  MarketStatusModel({
    required this.status,
    required this.totalShops,
    required this.openShops,
    required this.suspiciousShops,
    required this.closedShops,
  });

  factory MarketStatusModel.fromJson(Map<String, dynamic> json) {
    return MarketStatusModel(
      status: json['status'] as String,
      totalShops: json['total_shops'] as int? ?? 0,
      openShops: json['open_shops'] as int? ?? 0,
      suspiciousShops: json['suspicious_shops'] as int? ?? 0,
      closedShops: json['closed_shops'] as int? ?? 0,
    );
  }
}

