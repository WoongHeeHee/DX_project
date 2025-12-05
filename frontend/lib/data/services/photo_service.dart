import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/photo_models.dart';

/// 사진 업로드 관련 API 서비스
class PhotoService {
  final ApiService _apiService;
  final Dio _dio;

  PhotoService(this._apiService) : _dio = Dio();

  /// 사진 업로드 초기화 (presigned URL 받기)
  Future<PhotoUploadInitResponse> initPhotoUpload({
    required double lat,
    required double lng,
    required DateTime takenAt,
    bool isMember = false,
  }) async {
    final response = await _apiService.post(
      '/uploads/photo-init',
      data: {
        'lat': lat,
        'lng': lng,
        'taken_at': takenAt.toUtc().toIso8601String(),
        'is_member': isMember,
      },
    );

    return PhotoUploadInitResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// S3에 직접 업로드 (presigned URL 사용, PUT 방식)
  Future<void> uploadPhotoToS3({
    required String presignedUrl,
    required Uint8List imageBytes,
  }) async {
    try {
      await _dio.put(
        presignedUrl,
        data: imageBytes,
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
          },
        ),
      );
    } on DioException catch (e) {
      throw Exception('이미지 업로드 실패: ${e.message}');
    }
  }

  /// 사진 업로드 완료 알림
  Future<void> completePhotoUpload({
    required String uploadToken,
    required String s3Key,
    required double lat,
    required double lng,
    required DateTime takenAt,
    String? uploaderUserId,
    String? photoType,
  }) async {
    await _apiService.post(
      '/uploads/photo-complete',
      data: {
        'upload_token': uploadToken,
        's3_key': s3Key,
        'lat': lat,
        'lng': lng,
        'taken_at': takenAt.toUtc().toIso8601String(),
        if (uploaderUserId != null) 'uploader_user_id': uploaderUserId,
        if (photoType != null) 'photo_type': photoType,
      },
    );
  }

  /// 제보 완료 (가게 선택 후)
  Future<void> completeReport({
    required String uploadToken,
    required String shopId,
  }) async {
    await _apiService.post(
      '/uploads/report-complete',
      data: {
        'upload_token': uploadToken,
        'shop_id': shopId,
      },
    );
  }

  /// 사진 정보 조회
  Future<PhotoModel> getPhoto(String photoId) async {
    final response = await _apiService.get('/uploads/photo/$photoId');
    return PhotoModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// 내 사진 목록
  Future<List<PhotoModel>> getMyPhotos({
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final response = await _apiService.get(
      '/uploads/my-photos',
      queryParameters: queryParams,
    );

    return (response.data as List)
        .map((json) => PhotoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 사진 삭제
  Future<void> deletePhoto(String photoId) async {
    await _apiService.delete('/uploads/photo/$photoId');
  }
}

