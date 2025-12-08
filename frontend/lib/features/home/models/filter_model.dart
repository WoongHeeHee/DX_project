// lib/features/home/models/filter_model.dart

/// 필터 모델 클래스
class FilterModel {
  final String id;
  final String name;
  final String? flagImageUrl; // 국기 이미지 URL (나중에 사용)

  FilterModel({
    required this.id,
    required this.name,
    this.flagImageUrl,
  });
}

/// 국가 필터 모델
class CountryFilter extends FilterModel {
  CountryFilter({
    required super.id,
    required super.name,
    super.flagImageUrl,
  });
}

/// 연령 필터 모델
class AgeFilter extends FilterModel {
  AgeFilter({
    required super.id,
    required super.name,
  });
}

