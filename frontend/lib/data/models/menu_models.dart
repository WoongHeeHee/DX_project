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
  final DateTime? createdAt;

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
    this.createdAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    // null 안전 처리를 위한 헬퍼 함수
    String? _parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        return value.isEmpty ? null : value;
      }
      return value.toString();
    }

    return MenuItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: _parseString(json['name_en']),
      nameZh: _parseString(json['name_zh']),
      nameJa: _parseString(json['name_ja']),
      description: _parseString(json['description']),
      descriptionEn: _parseString(json['description_en']),
      descriptionZh: _parseString(json['description_zh']),
      descriptionJa: _parseString(json['description_ja']),
      similarFood: _parseString(json['similar_food']),
      similarFoodEn: _parseString(json['similar_food_en']),
      similarFoodZh: _parseString(json['similar_food_zh']),
      similarFoodJa: _parseString(json['similar_food_ja']),
      repImageUrl: _parseString(json['rep_image_url']),
      price: _parseString(json['price']),
      contains: _parseString(json['contains']),
      containsEn: _parseString(json['contains_en']),
      containsZh: _parseString(json['contains_zh']),
      containsJa: _parseString(json['contains_ja']),
      mayContains: _parseString(json['may_contains']),
      mayContainsEn: _parseString(json['may_contains_en']),
      mayContainsZh: _parseString(json['may_contains_zh']),
      mayContainsJa: _parseString(json['may_contains_ja']),
      category: _parseString(json['category']),
      spiceLevel: json['spice_level'] as int? ?? 1,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
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
    super.createdAt,
    required this.isSaved,
  });

  factory MenuItemDetailModel.fromJson(Map<String, dynamic> json) {
    // null 안전 처리를 위한 헬퍼 함수
    String? _parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        return value.isEmpty ? null : value;
      }
      return value.toString();
    }

    return MenuItemDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: _parseString(json['name_en']),
      nameZh: _parseString(json['name_zh']),
      nameJa: _parseString(json['name_ja']),
      description: _parseString(json['description']),
      descriptionEn: _parseString(json['description_en']),
      descriptionZh: _parseString(json['description_zh']),
      descriptionJa: _parseString(json['description_ja']),
      similarFood: _parseString(json['similar_food']),
      similarFoodEn: _parseString(json['similar_food_en']),
      similarFoodZh: _parseString(json['similar_food_zh']),
      similarFoodJa: _parseString(json['similar_food_ja']),
      repImageUrl: _parseString(json['rep_image_url']),
      price: _parseString(json['price']),
      contains: _parseString(json['contains']),
      containsEn: _parseString(json['contains_en']),
      containsZh: _parseString(json['contains_zh']),
      containsJa: _parseString(json['contains_ja']),
      mayContains: _parseString(json['may_contains']),
      mayContainsEn: _parseString(json['may_contains_en']),
      mayContainsZh: _parseString(json['may_contains_zh']),
      mayContainsJa: _parseString(json['may_contains_ja']),
      category: _parseString(json['category']),
      spiceLevel: json['spice_level'] as int? ?? 1,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isSaved: json['is_saved'] as bool? ?? false,
    );
  }
}

