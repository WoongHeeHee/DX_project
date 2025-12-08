// lib/features/home/models/trend_banner_model.dart

/// 트렌드 배너 모델
class TrendBannerModel {
  final String id;
  final String foodName;
  final String description;
  final String imageUrl;
  final String? countryId; // 국가 필터 ID (선택적)
  final String? ageId; // 나이 필터 ID (선택적)

  TrendBannerModel({
    required this.id,
    required this.foodName,
    required this.description,
    required this.imageUrl,
    this.countryId,
    this.ageId,
  });
}

