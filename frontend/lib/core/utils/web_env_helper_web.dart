// lib/core/utils/web_env_helper_web.dart

import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// 웹 환경에서 사용되는 구현
String? getEnvValueImpl(String key) {
  try {
    // window.ENV 확인
    final env = js.context['ENV'];
    if (env == null) {
      debugPrint('[WebEnvHelper] ⚠️ window.ENV가 설정되지 않았습니다. index.html의 스크립트가 실행되었는지 확인하세요.');
      return null;
    }
    
    // ENV 객체가 JsObject인지 확인
    if (env is! js.JsObject) {
      debugPrint('[WebEnvHelper] ⚠️ window.ENV가 올바른 형식이 아닙니다.');
      return null;
    }
    
    final envObject = env;
    
    // 키 존재 여부 확인 (직접 접근 시도)
    try {
      final value = envObject[key];
      if (value == null) {
        debugPrint('[WebEnvHelper] ⚠️ window.ENV[$key]가 null입니다.');
        return null;
      }
      
      final valueStr = value.toString();
      if (valueStr.isEmpty) {
        debugPrint('[WebEnvHelper] ⚠️ window.ENV[$key]가 빈 문자열입니다.');
        return null;
      }
      
      if (valueStr == 'null') {
        debugPrint('[WebEnvHelper] ⚠️ window.ENV[$key]가 문자열 "null"입니다.');
        return null;
      }
      
      if (valueStr.contains('your-')) {
        debugPrint('[WebEnvHelper] ⚠️ window.ENV[$key]가 플레이스홀더 값을 포함합니다: $valueStr');
        return null;
      }
      
      debugPrint('[WebEnvHelper] ✅ window.ENV에서 $key 읽기 성공: $valueStr');
      return valueStr;
    } catch (e) {
      debugPrint('[WebEnvHelper] ⚠️ window.ENV[$key] 접근 실패: $e');
      return null;
    }
  } catch (e, stackTrace) {
    debugPrint('[WebEnvHelper] ❌ window.ENV에서 $key 읽기 오류: $e');
    debugPrint('[WebEnvHelper] 스택 트레이스: $stackTrace');
  }
  return null;
}

