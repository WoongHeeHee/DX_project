// lib/features/search/models/search_result_model.dart

/// 검색 결과 모델
class SearchResultModel {
  final String id;
  final String menuName; // 메뉴명
  final String imageUrl; // 이미지 URL
  final String description; // 상세 설명
  final String? nearestMarketName; // 가장 가까운 시장명 (서버에서 제공)
  final String? nearestMarketId; // 가장 가까운 시장 ID (서버에서 제공)

  SearchResultModel({
    required this.id,
    required this.menuName,
    required this.imageUrl,
    required this.description,
    this.nearestMarketName,
    this.nearestMarketId,
  });
}

