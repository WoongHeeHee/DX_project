// lib/features/home/models/food_model.dart

/// 음식 모델
class FoodModel {
  final String id;
  final String name; // 표시용 (locale 반영)
  final String baseName; // 이미지 경로용 원본(ko) 이름
  final String category; // Meals, Snacks, Sweets, Drink
  final String imageUrl;
  final String description;
  final List<String> imageUrls; // 상세 페이지용 이미지들
  final int spiciness; // 맵기 레벨 (1-5)
  final String spicinessDescription; // 맵기 설명
  final List<SimilarFood> similarFoods; // 비슷한 음식들
  final List<String> contains; // 포함된 알레르기 유발물질
  final List<String> mayContain; // 포함될 수 있는 알레르기 유발물질

  FoodModel({
    required this.id,
    required this.name,
    required this.baseName,
    required this.category,
    required this.imageUrl,
    required this.description,
    required this.imageUrls,
    required this.spiciness,
    required this.spicinessDescription,
    required this.similarFoods,
    required this.contains,
    required this.mayContain,
  });
}

/// 비슷한 음식 모델
class SimilarFood {
  final String id;
  final String name;
  final String description;

  SimilarFood({
    required this.id,
    required this.name,
    required this.description,
  });
}
