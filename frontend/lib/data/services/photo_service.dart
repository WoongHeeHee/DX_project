import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/photo_models.dart';

/// 사진 업로드 관련 API 서비스
class PhotoService {
  final ApiService _apiService;

  PhotoService(this._apiService);

  /// Presigned URL 발급 (새 API 스펙)
  Future<PhotoPresignResponse> presignPhotoUpload() async {
    final response = await _apiService.post(
      '/photos/presign',
    );

    return PhotoPresignResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 사진 업로드 완료 처리 (새 API 스펙)
  Future<PhotoUploadResponse> uploadPhoto({
    required String photoUrl,
    required double lat,
    required double lng,
    required String photoType, // 'review' | 'report' | 'search'
  }) async {
    final response = await _apiService.post(
      '/photos',
      data: {
        'photo_url': photoUrl,
        'lat': lat,
        'lng': lng,
        'photo_type': photoType,
      },
    );

    return PhotoUploadResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// 사진 업로드 초기화 (기존 API - 하위 호환성 유지)
  @Deprecated('Use presignPhotoUpload() instead')
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
      // Dio의 기본 헤더 자동 추가 방지
      // presigned URL의 서명에 포함된 헤더만 정확히 일치시켜야 함
      final bytesList = imageBytes.toList();
      
      // 별도의 Dio 인스턴스 생성 (기본 인터셉터 제거)
      final uploadDio = Dio();
      
      await uploadDio.put(
        presignedUrl,
        data: bytesList,
        options: Options(
          headers: {
            // presigned URL 생성 시 ContentType 파라미터로 지정한 값과 정확히 일치해야 함
            // 백엔드에서 서명에 포함된 헤더만 여기에 포함시켜야 함
            'Content-Type': 'image/jpeg',
          },
          // 바이너리 데이터를 그대로 전송
          responseType: ResponseType.bytes,
          // 200-299 범위의 상태 코드만 성공으로 처리
          validateStatus: (status) => status != null && status >= 200 && status < 300,
          // contentType 옵션 제거: headers의 'Content-Type'과 중복되어 충돌할 수 있음
          // followRedirects: false, // 필요시에만 사용
        ),
      );
    } on DioException catch (e) {
      // 더 자세한 오류 정보 포함 (S3 XML 응답 파싱)
      String errorMessage;
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final statusMessage = e.response?.statusMessage;
        final responseData = e.response?.data;
        errorMessage = '이미지 업로드 실패: $statusCode - $statusMessage';
        
        // S3 오류 응답은 XML 형식이므로 파싱하여 상세 정보 추출
        if (responseData != null) {
          try {
            String xmlText;
            if (responseData is List<int>) {
              xmlText = String.fromCharCodes(responseData);
            } else if (responseData is String) {
              xmlText = responseData;
            } else {
              xmlText = responseData.toString();
            }
            
            errorMessage += '\n\n=== S3 오류 응답 (XML) ===\n$xmlText';
            
            // XML에서 주요 오류 정보 추출 시도
            if (xmlText.contains('<Code>')) {
              final codeMatch = RegExp(r'<Code>(.*?)</Code>').firstMatch(xmlText);
              final messageMatch = RegExp(r'<Message>(.*?)</Message>').firstMatch(xmlText);
              
              if (codeMatch != null) {
                errorMessage += '\n\n오류 코드: ${codeMatch.group(1)}';
              }
              if (messageMatch != null) {
                errorMessage += '\n오류 메시지: ${messageMatch.group(1)}';
              }
            }
          } catch (parseError) {
            // XML 파싱 실패 시 원본 텍스트만 포함
            errorMessage += '\n응답 파싱 실패: $parseError';
          }
        }
      } else {
        errorMessage = '이미지 업로드 실패: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('이미지 업로드 실패: $e');
    }
  }

  /// 사진 업로드 완료 알림 (기존 API - 하위 호환성 유지)
  @Deprecated('Use uploadPhoto() instead')
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

