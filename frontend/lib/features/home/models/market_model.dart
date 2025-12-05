// lib/features/home/models/market_model.dart

/// 시장 상세 정보 모델
class MarketModel {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls; // 이미지 URL 리스트
  final List<MustTryItem> mustTryItems; // Must try 메뉴 리스트
  final String address; // 주소
  final String operatingHours; // 영업 정보
  final String transportation; // 교통 정보
  final String parking; // 주차 정보
  final String restroom; // 화장실 정보
  final String mapImageUrl; // 지도 이미지 URL

  MarketModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.mustTryItems,
    required this.address,
    required this.operatingHours,
    required this.transportation,
    required this.parking,
    required this.restroom,
    required this.mapImageUrl,
  });
}

/// Must try 메뉴 아이템
class MustTryItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  MustTryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });
}

