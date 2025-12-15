// lib/core/utils/image_utils.dart

/// 이미지 URL 유틸리티 함수
class ImageUtils {
  /// CloudFront CDN 기본 URL
  static const String cdnBaseUrl = 'https://dnzeuzpu74ulj.cloudfront.net';

  /// s3_key를 CDN URL로 변환 (성능 최적화: presigned URL 생성 오버헤드 제거)
  /// 
  /// Args:
  ///   s3Key: S3 키 (예: "photos/20240101_100000_abc123.jpg")
  /// 
  /// Returns:
  ///   CDN URL (예: "https://dnzeuzpu74ulj.cloudfront.net/photos/20240101_100000_abc123.jpg")
  static String s3KeyToCdnUrl(String? s3Key) {
    if (s3Key == null || s3Key.isEmpty) {
      return '';
    }
    
    final trimmed = s3Key.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    
    // s3_key가 이미 전체 URL인 경우 그대로 반환
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    
    // 앞의 슬래시 제거 (중복 방지)
    final cleanKey = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    
    // s3_key를 CDN URL로 변환
    return '$cdnBaseUrl/$cleanKey';
  }

  /// 썸네일 s3_key를 CDN URL로 변환
  static String thumbnailS3KeyToCdnUrl(String? thumbnailS3Key) {
    return s3KeyToCdnUrl(thumbnailS3Key);
  }
}

