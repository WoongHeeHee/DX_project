import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

/// 기본 API 서비스 클래스
class ApiService {
  late Dio _dio;
  static const String _tokenKey = 'access_token';

  ApiService() {
    final baseUrl = AppConfig.apiBaseUrl;
    debugPrint('ApiService 초기화 - baseUrl: $baseUrl');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: AppConfig.apiTimeout),
        receiveTimeout: Duration(seconds: AppConfig.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
        },
        // 웹 환경에서 CORS 요청을 위한 설정
        validateStatus: (status) {
          return status != null && status >= 200 && status < 500;
        },
      ),
    );

    // 인터셉터 추가: 요청 시 토큰 자동 추가 및 로깅
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('═══════════════════════════════════════════════════');
          debugPrint('📤 API 요청 시작');
          debugPrint('───────────────────────────────────────────────────');
          debugPrint('메서드: ${options.method}');
          debugPrint('전체 URL: ${options.baseUrl}${options.path}');
          debugPrint('경로: ${options.path}');
          
          if (kIsWeb) {
            debugPrint('🌐 웹 환경에서 실행 중');
            debugPrint('   - 브라우저 개발자 도구의 Network 탭에서 요청 상세 정보를 확인하세요');
            debugPrint('   - 브라우저 콘솔에서 CORS 에러 메시지를 확인하세요');
          }
          
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('🔑 인증 토큰: Bearer ${token.substring(0, 20)}... (${token.length}자)');
          } else {
            debugPrint('🔓 인증 토큰: 없음 (익명 요청)');
          }
          
          debugPrint('📋 요청 헤더:');
          options.headers.forEach((key, value) {
            if (key.toLowerCase() == 'authorization') {
              debugPrint('   - $key: Bearer *** (토큰 숨김)');
            } else {
              debugPrint('   - $key: $value');
            }
          });
          
          if (options.data != null) {
            debugPrint('📦 요청 본문 데이터:');
            final dataStr = options.data.toString();
            if (dataStr.length > 500) {
              debugPrint('   ${dataStr.substring(0, 500)}... (전체 ${dataStr.length}자)');
            } else {
              debugPrint('   $dataStr');
            }
          }
          
          debugPrint('⏱️ 연결 타임아웃: ${options.connectTimeout}');
          debugPrint('⏱️ 수신 타임아웃: ${options.receiveTimeout}');
          debugPrint('═══════════════════════════════════════════════════');
          
          return handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('═══════════════════════════════════════════════════');
          debugPrint('❌ API 요청 실패');
          debugPrint('───────────────────────────────────────────────────');
          debugPrint('에러 타입: ${error.type}');
          debugPrint('에러 메시지: ${error.message}');
          debugPrint('요청 URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
          debugPrint('요청 메서드: ${error.requestOptions.method}');
          
          if (kIsWeb) {
            debugPrint('🌐 웹 환경에서 실행 중');
            final requestOrigin = Uri.parse(error.requestOptions.baseUrl).origin;
            debugPrint('   - 요청 대상 서버: $requestOrigin');
            debugPrint('   - 브라우저 개발자 도구의 Network 탭에서 요청 상세 정보를 확인하세요');
            debugPrint('   - 브라우저 콘솔에서 CORS 에러 메시지를 확인하세요');
            debugPrint('   - 현재 프론트엔드 주소와 요청 대상 서버가 다른 경우 CORS 설정이 필요합니다');
          }
          
          if (error.response != null) {
            debugPrint('📥 서버 응답 수신됨:');
            debugPrint('   - 상태 코드: ${error.response!.statusCode}');
            debugPrint('   - 응답 헤더:');
            error.response!.headers.forEach((key, values) {
              debugPrint('     - $key: ${values.join(", ")}');
            });
            debugPrint('   - 응답 데이터: ${error.response!.data}');
          } else {
            debugPrint('📭 서버 응답 없음');
            debugPrint('   - 서버에 연결하지 못했습니다.');
            debugPrint('   - 가능한 원인:');
            debugPrint('     1. 백엔드 서버가 실행되지 않음');
            debugPrint('     2. CORS 정책에 의해 차단됨');
            debugPrint('     3. 네트워크 연결 문제');
            debugPrint('     4. 방화벽이나 프록시에 의해 차단됨');
          }
          
          debugPrint('📋 요청 헤더:');
          error.requestOptions.headers.forEach((key, value) {
            if (key.toLowerCase() == 'authorization') {
              debugPrint('   - $key: Bearer *** (토큰 숨김)');
            } else {
              debugPrint('   - $key: $value');
            }
          });
          
          if (error.requestOptions.data != null) {
            debugPrint('📦 요청 본문 데이터:');
            final dataStr = error.requestOptions.data.toString();
            if (dataStr.length > 500) {
              debugPrint('   ${dataStr.substring(0, 500)}... (전체 ${dataStr.length}자)');
            } else {
              debugPrint('   $dataStr');
            }
          }
          
          debugPrint('🔗 전체 요청 URL: ${error.requestOptions.uri}');
          debugPrint('═══════════════════════════════════════════════════');
          
          // 401 에러 시 토큰 제거
          if (error.response?.statusCode == 401) {
            _removeToken();
          }
          return handler.next(error);
        },
        onResponse: (response, handler) {
          debugPrint('═══════════════════════════════════════════════════');
          debugPrint('✅ API 요청 성공');
          debugPrint('───────────────────────────────────────────────────');
          debugPrint('요청 URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
          debugPrint('상태 코드: ${response.statusCode}');
          debugPrint('응답 헤더:');
          response.headers.forEach((key, values) {
            debugPrint('   - $key: ${values.join(", ")}');
          });
          
          final dataStr = response.data.toString();
          if (dataStr.length > 500) {
            debugPrint('응답 데이터: ${dataStr.substring(0, 500)}... (전체 ${dataStr.length}자)');
          } else {
            debugPrint('응답 데이터: $dataStr');
          }
          debugPrint('═══════════════════════════════════════════════════');
          
          return handler.next(response);
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
    debugPrint('_handleError: type=${error.type}, message=${error.message}');
    
    if (error.response != null) {
      // 서버에서 응답이 온 경우
      final statusCode = error.response!.statusCode;
      final message = error.response!.data?['detail'] ?? 
                     error.response!.data?['message'] ?? 
                     '서버 오류가 발생했습니다.';
      
      debugPrint('서버 응답 에러: $statusCode - $message');
      
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
      debugPrint('타임아웃 에러: ${error.type}');
      return ApiException(
        message: '요청 시간이 초과되었습니다. 서버가 실행 중인지 확인해주세요.',
        statusCode: 0,
      );
    } else if (error.type == DioExceptionType.connectionError) {
      debugPrint('연결 에러: ${error.message}');
      // 웹 환경에서의 연결 에러는 CORS 문제일 가능성이 높음
      String errorMessage = '서버에 연결할 수 없습니다.';
      if (kIsWeb) {
        errorMessage += '\n\n가능한 원인:\n';
        errorMessage += '1. CORS 설정 확인: 백엔드 서버가 현재 프론트엔드 오리진(http://localhost:50000 또는 http://127.0.0.1:50000)을 허용하는지 확인하세요.\n';
        errorMessage += '2. 서버 실행 확인: 백엔드 서버(${error.requestOptions.baseUrl})가 실행 중인지 확인하세요.\n';
        errorMessage += '   - 브라우저에서 ${error.requestOptions.baseUrl}/health 를 열어 서버 상태를 확인하세요.\n';
        errorMessage += '3. 백엔드 서버 로그 확인: 백엔드 서버 로그에서 CORS 오류나 요청이 도달했는지 확인하세요.\n';
        errorMessage += '4. 네트워크 연결: 네트워크 연결 상태를 확인하세요.';
      } else {
        errorMessage += ' 네트워크 연결과 서버 주소(${error.requestOptions.baseUrl})를 확인해주세요.';
      }
      return ApiException(
        message: errorMessage,
        statusCode: 0,
      );
    } else {
      debugPrint('기타 에러: ${error.type} - ${error.message}');
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

