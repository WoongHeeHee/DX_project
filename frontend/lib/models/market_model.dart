import 'package:uuid/uuid.dart';

class MarketModel {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameZh;
  final String? nameJa;
  final String? description;
  final String? silhouetteUrl;
  final DateTime createdAt;

  MarketModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameZh,
    this.nameJa,
    this.description,
    this.silhouetteUrl,
    required this.createdAt,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      nameZh: json['name_zh'],
      nameJa: json['name_ja'],
      description: json['description'],
      silhouetteUrl: json['silhouette_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

