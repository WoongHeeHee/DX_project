import 'package:uuid/uuid.dart';

class MenuModel {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameZh;
  final String? nameJa;
  final String? description;
  final String? category;
  final int? spicyLevel;
  final List<String>? imageUrls;
  final List<String>? similarMenus;
  final List<String>? allergies;
  final List<String>? mayContainAllergies;

  MenuModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameZh,
    this.nameJa,
    this.description,
    this.category,
    this.spicyLevel,
    this.imageUrls,
    this.similarMenus,
    this.allergies,
    this.mayContainAllergies,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      nameZh: json['name_zh'],
      nameJa: json['name_ja'],
      description: json['description'],
      category: json['category'],
      spicyLevel: json['spicy_level'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      similarMenus: json['similar_menus'] != null
          ? List<String>.from(json['similar_menus'])
          : null,
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : null,
      mayContainAllergies: json['may_contain_allergies'] != null
          ? List<String>.from(json['may_contain_allergies'])
          : null,
    );
  }
}

