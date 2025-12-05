import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';

class PhotoService {
  final ApiService _apiService;

  PhotoService(this._apiService);

  // 사진 업로드 초기화 (presigned URL 생성)
  Future<Map<String, dynamic>> initPhotoUpload({
    required bool isMember,
    required double lat,
    required double lng,
    String? photoType,
  }) async {
    try {
      final response = await _apiService.post(
        '/uploads/photo-init',
        data: {
          'is_member': isMember,
          'lat': lat,
          'lng': lng,
          'photo_type': photoType ?? 'report',
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // 사진 업로드 (presigned URL로 직접 업로드)
  Future<void> uploadPhotoToS3(String presignedUrl, File imageFile) async {
    try {
      await _apiService.dio.put(
        presignedUrl,
        data: await imageFile.readAsBytes(),
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // 사진 업로드 완료 처리
  Future<void> completePhotoUpload({
    required String s3Key,
    required double lat,
    required double lng,
    String? uploadToken,
    String? uploaderUserId,
    String? shopId,
    String? photoType,
  }) async {
    try {
      await _apiService.post(
        '/uploads/photo-complete',
        data: {
          's3_key': s3Key,
          'lat': lat,
          'lng': lng,
          'upload_token': uploadToken,
          'uploader_user_id': uploaderUserId,
          'shop_id': shopId,
          'photo_type': photoType ?? 'report',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // 사진 업로드 전체 프로세스
  Future<String> uploadPhoto({
    required File imageFile,
    required double lat,
    required double lng,
    required bool isMember,
    String? shopId,
    String? photoType,
  }) async {
    try {
      // 1. 업로드 초기화
      final initResponse = await initPhotoUpload(
        isMember: isMember,
        lat: lat,
        lng: lng,
        photoType: photoType,
      );

      final presignedUrl = initResponse['presigned_url'] as String;
      final s3Key = initResponse['s3_key'] as String;
      final uploadToken = initResponse['upload_token'] as String?;

      // 2. S3에 직접 업로드
      await uploadPhotoToS3(presignedUrl, imageFile);

      // 3. 업로드 완료 처리
      await completePhotoUpload(
        s3Key: s3Key,
        lat: lat,
        lng: lng,
        uploadToken: uploadToken,
        shopId: shopId,
        photoType: photoType,
      );

      return s3Key;
    } catch (e) {
      rethrow;
    }
  }
}

