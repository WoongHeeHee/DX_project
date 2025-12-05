import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';

/// 기본 API 서비스 클래스
class ApiService {
  late Dio _dio;
  static const String _tokenKey = 'access_token';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(seconds: AppConfig.apiTimeout),
        receiveTimeout: Duration(seconds: AppConfig.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // 인터셉터 추가: 요청 시 토큰 자동 추가
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // 401 에러 시 토큰 제거
          if (error.response?.statusCode == 401) {
            _removeToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// 토큰 저장
  Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// 토큰 가져오기
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 토큰 제거
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// 로그아웃 (토큰 제거)
  Future<void> logout() async {
    await _removeToken();
  }

  /// GET 요청
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST 요청
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT 요청
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE 요청
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 에러 처리
  Exception _handleError(DioException error) {
    if (error.response != null) {
      // 서버에서 응답이 온 경우
      final statusCode = error.response!.statusCode;
      final message = error.response!.data?['detail'] ?? 
                     error.response!.data?['message'] ?? 
                     '서버 오류가 발생했습니다.';
      
      // 401 에러는 특별 처리 (인증 에러)
      if (statusCode == 401) {
        return AuthException(
          message: message,
          statusCode: statusCode,
          data: error.response!.data,
        );
      }
      
      return ApiException(
        message: message,
        statusCode: statusCode,
        data: error.response!.data,
      );
    } else if (error.type == DioExceptionType.connectionTimeout ||
               error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: '요청 시간이 초과되었습니다.',
        statusCode: 0,
      );
    } else if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        message: '서버에 연결할 수 없습니다.',
        statusCode: 0,
      );
    } else {
      return ApiException(
        message: error.message ?? '알 수 없는 오류가 발생했습니다.',
        statusCode: 0,
      );
    }
  }
}

/// API 예외 클래스
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

/// 인증 예외 클래스 (401 에러)
class AuthException extends ApiException {
  AuthException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

