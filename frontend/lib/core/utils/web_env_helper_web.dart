// lib/core/utils/web_env_helper_web.dart

import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// 웹 환경에서 사용되는 구현
String? getEnvValueImpl(String key) {
  try {
    final env = js.context['ENV'];
    if (env != null) {
      final value = env[key];
      if (value != null) {
        final valueStr = value.toString();
        if (valueStr.isNotEmpty && 
            valueStr != 'null' && 
            !valueStr.contains('your-')) {
          debugPrint('웹 환경 - window.ENV에서 $key 사용');
          return valueStr;
        }
      }
    }
  } catch (e) {
    debugPrint('window.ENV에서 $key 읽기 오류: $e');
  }
  return null;
}

