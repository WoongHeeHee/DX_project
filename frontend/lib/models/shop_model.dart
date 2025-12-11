import 'package:uuid/uuid.dart';

class ShopModel {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameZh;
  final String? nameJa;
  final double lat;
  final double lng;
  final String? address;
  final String? repImageUrl;
  final String? openTime;
  final String? closeTime;
  final String? closedDays;  // DB에서 문자열로 저장됨
  final double? averagePrice;
  final String? status;  // "green", "yellow", "red"
  final List<String>? imageUrls;  // 실시간 사진 URL 리스트 (최대 3개)

  ShopModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameZh,
    this.nameJa,
    required this.lat,
    required this.lng,
    this.address,
    this.repImageUrl,
    this.openTime,
    this.closeTime,
    this.closedDays,
    this.averagePrice,
    this.status,
    this.imageUrls,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      nameZh: json['name_zh'],
      nameJa: json['name_ja'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'],
      repImageUrl: json['rep_image_url'],
      openTime: json['open_time'],
      closeTime: json['close_time'],
      closedDays: json['closed_days'] as String?,
      averagePrice: json['average_price'] != null
          ? (json['average_price'] as num).toDouble()
          : null,
      status: json['status'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

