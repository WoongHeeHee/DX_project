/// 메뉴 아이템 모델
class MenuItemModel {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameZh;
  final String? nameJa;
  final String? description;
  final String? descriptionEn;
  final String? descriptionZh;
  final String? descriptionJa;
  final String? similarFood;
  final String? similarFoodEn;
  final String? similarFoodZh;
  final String? similarFoodJa;
  final String? repImageUrl;
  final String? price;
  final String? contains;
  final String? containsEn;
  final String? containsZh;
  final String? containsJa;
  final String? mayContains;
  final String? mayContainsEn;
  final String? mayContainsZh;
  final String? mayContainsJa;
  final String? category;
  final int spiceLevel;
  final DateTime createdAt;

  MenuItemModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameZh,
    this.nameJa,
    this.description,
    this.descriptionEn,
    this.descriptionZh,
    this.descriptionJa,
    this.similarFood,
    this.similarFoodEn,
    this.similarFoodZh,
    this.similarFoodJa,
    this.repImageUrl,
    this.price,
    this.contains,
    this.containsEn,
    this.containsZh,
    this.containsJa,
    this.mayContains,
    this.mayContainsEn,
    this.mayContainsZh,
    this.mayContainsJa,
    this.category,
    required this.spiceLevel,
    required this.createdAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      nameZh: json['name_zh'] as String?,
      nameJa: json['name_ja'] as String?,
      description: json['description'] as String?,
      descriptionEn: json['description_en'] as String?,
      descriptionZh: json['description_zh'] as String?,
      descriptionJa: json['description_ja'] as String?,
      similarFood: json['similar_food'] as String?,
      similarFoodEn: json['similar_food_en'] as String?,
      similarFoodZh: json['similar_food_zh'] as String?,
      similarFoodJa: json['similar_food_ja'] as String?,
      repImageUrl: json['rep_image_url'] as String?,
      price: json['price'] as String?,
      contains: json['contains'] as String?,
      containsEn: json['contains_en'] as String?,
      containsZh: json['contains_zh'] as String?,
      containsJa: json['contains_ja'] as String?,
      mayContains: json['may_contains'] as String?,
      mayContainsEn: json['may_contains_en'] as String?,
      mayContainsZh: json['may_contains_zh'] as String?,
      mayContainsJa: json['may_contains_ja'] as String?,
      category: json['category'] as String?,
      spiceLevel: json['spice_level'] as int? ?? 1,
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

  /// locale에 맞는 비슷한 음식 반환
  String? getSimilarFoodByLocale(String locale) {
    switch (locale) {
      case 'en':
        return similarFoodEn ?? similarFood;
      case 'zh':
        return similarFoodZh ?? similarFood;
      case 'ja':
        return similarFoodJa ?? similarFood;
      default:
        return similarFood;
    }
  }

  /// locale에 맞는 알레르기 정보 반환
  String? getContainsByLocale(String locale) {
    switch (locale) {
      case 'en':
        return containsEn ?? contains;
      case 'zh':
        return containsZh ?? contains;
      case 'ja':
        return containsJa ?? contains;
      default:
        return contains;
    }
  }

  /// locale에 맞는 가능한 알레르기 정보 반환
  String? getMayContainsByLocale(String locale) {
    switch (locale) {
      case 'en':
        return mayContainsEn ?? mayContains;
      case 'zh':
        return mayContainsZh ?? mayContains;
      case 'ja':
        return mayContainsJa ?? mayContains;
      default:
        return mayContains;
    }
  }
}

/// 메뉴 상세 정보 모델 (저장 여부 포함)
class MenuItemDetailModel extends MenuItemModel {
  final bool isSaved;

  MenuItemDetailModel({
    required super.id,
    required super.name,
    super.nameEn,
    super.nameZh,
    super.nameJa,
    super.description,
    super.descriptionEn,
    super.descriptionZh,
    super.descriptionJa,
    super.similarFood,
    super.similarFoodEn,
    super.similarFoodZh,
    super.similarFoodJa,
    super.repImageUrl,
    super.price,
    super.contains,
    super.containsEn,
    super.containsZh,
    super.containsJa,
    super.mayContains,
    super.mayContainsEn,
    super.mayContainsZh,
    super.mayContainsJa,
    super.category,
    required super.spiceLevel,
    required super.createdAt,
    required this.isSaved,
  });

  factory MenuItemDetailModel.fromJson(Map<String, dynamic> json) {
    return MenuItemDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      nameZh: json['name_zh'] as String?,
      nameJa: json['name_ja'] as String?,
      description: json['description'] as String?,
      descriptionEn: json['description_en'] as String?,
      descriptionZh: json['description_zh'] as String?,
      descriptionJa: json['description_ja'] as String?,
      similarFood: json['similar_food'] as String?,
      similarFoodEn: json['similar_food_en'] as String?,
      similarFoodZh: json['similar_food_zh'] as String?,
      similarFoodJa: json['similar_food_ja'] as String?,
      repImageUrl: json['rep_image_url'] as String?,
      price: json['price'] as String?,
      contains: json['contains'] as String?,
      containsEn: json['contains_en'] as String?,
      containsZh: json['contains_zh'] as String?,
      containsJa: json['contains_ja'] as String?,
      mayContains: json['may_contains'] as String?,
      mayContainsEn: json['may_contains_en'] as String?,
      mayContainsZh: json['may_contains_zh'] as String?,
      mayContainsJa: json['may_contains_ja'] as String?,
      category: json['category'] as String?,
      spiceLevel: json['spice_level'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      isSaved: json['is_saved'] as bool? ?? false,
    );
  }
}

