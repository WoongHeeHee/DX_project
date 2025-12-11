/// 사진 업로드 초기화 응답 모델 (기존 API - 하위 호환성 유지)
class PhotoUploadInitResponse {
  final bool success;
  final String presignedUrl;
  final String uploadToken;
  final String s3Key;
  final String message;

  PhotoUploadInitResponse({
    required this.success,
    required this.presignedUrl,
    required this.uploadToken,
    required this.s3Key,
    required this.message,
  });

  factory PhotoUploadInitResponse.fromJson(Map<String, dynamic> json) {
    return PhotoUploadInitResponse(
      success: json['success'] as bool? ?? true,
      presignedUrl: json['presigned_url'] as String,
      uploadToken: json['upload_token'] as String,
      s3Key: json['s3_key'] as String,
      message: json['message'] as String? ?? '',
    );
  }
}

/// Presigned URL 발급 응답 모델 (새 API)
class PhotoPresignResponse {
  final String uploadUrl;
  final String fileUrl;

  PhotoPresignResponse({
    required this.uploadUrl,
    required this.fileUrl,
  });

  factory PhotoPresignResponse.fromJson(Map<String, dynamic> json) {
    return PhotoPresignResponse(
      uploadUrl: json['upload_url'] as String,
      fileUrl: json['file_url'] as String,
    );
  }
}

/// 사진 업로드 완료 응답 모델 (새 API)
class PhotoUploadResponse {
  final bool success;
  final String message;
  final List<String>? photoIds;
  final String? matchedMenu;

  PhotoUploadResponse({
    required this.success,
    required this.message,
    this.photoIds,
    this.matchedMenu,
  });

  factory PhotoUploadResponse.fromJson(Map<String, dynamic> json) {
    return PhotoUploadResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      photoIds: json['photo_ids'] != null
          ? (json['photo_ids'] as List).map((e) => e.toString()).toList()
          : null,
      matchedMenu: json['matched_menu'] as String?,
    );
  }
}

/// 사진 모델
class PhotoModel {
  final String id;
  final String s3Key;
  final String? thumbnailS3Key;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double lat;
  final double lng;
  final DateTime takenAt;
  final bool processed;
  final String? menuItemId;
  final DateTime createdAt;

  PhotoModel({
    required this.id,
    required this.s3Key,
    this.thumbnailS3Key,
    this.imageUrl,
    this.thumbnailUrl,
    required this.lat,
    required this.lng,
    required this.takenAt,
    required this.processed,
    this.menuItemId,
    required this.createdAt,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      s3Key: json['s3_key'] as String,
      thumbnailS3Key: json['thumbnail_s3_key'] as String?,
      imageUrl: json['image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      takenAt: DateTime.parse(json['taken_at'] as String),
      processed: json['processed'] as bool? ?? false,
      menuItemId: json['menu_item_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

