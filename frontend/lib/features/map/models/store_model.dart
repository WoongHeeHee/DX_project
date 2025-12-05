// lib/features/map/models/store_model.dart

/// 가게 모델
class StoreModel {
  final String id;
  final String name; // 가게명
  final List<String> imageUrls; // 이미지 URL 리스트 (최대 3개)
  final String address; // 주소
  final StoreStatus status; // 영업 상태 (적/황/청)
  final bool isSaved; // 저장 여부
  final String? operatingHours; // 영업시간 (SAVED 탭용)
  final String? closedDays; // 휴무일 (SAVED 탭용)

  StoreModel({
    required this.id,
    required this.name,
    required this.imageUrls,
    required this.address,
    required this.status,
    this.isSaved = false,
    this.operatingHours,
    this.closedDays,
  });
}

/// 가게 영업 상태
enum StoreStatus {
  open, // 청색 - 영업 중
  closingSoon, // 황색 - 곧 마감
  closed, // 적색 - 영업 종료/휴무
}

