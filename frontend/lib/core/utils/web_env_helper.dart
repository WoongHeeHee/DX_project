// lib/core/utils/web_env_helper.dart

import 'package:flutter/foundation.dart';
import 'web_env_helper_web.dart' if (dart.library.io) 'web_env_helper_stub.dart';

/// 웹 환경에서 window.ENV를 통해 환경 변수를 읽는 헬퍼
class WebEnvHelper {
  /// 웹 환경에서 환경 변수 가져오기
  static String? getEnvValue(String key) {
    if (!kIsWeb) {
      return null;
    }
    return getEnvValueImpl(key);
  }

  /// 웹 환경에서 Google Client ID 가져오기
  static String? getGoogleClientId() {
    return getEnvValue('GOOGLE_CLIENT_ID');
  }

  /// 웹 환경에서 API Base URL 가져오기
  static String? getApiBaseUrl() {
    return getEnvValue('API_BASE_URL');
  }
}

