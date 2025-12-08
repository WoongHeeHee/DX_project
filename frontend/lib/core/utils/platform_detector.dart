import 'package:flutter/foundation.dart';

/// 플랫폼 감지를 위한 헬퍼
/// 조건부 import를 사용하여 웹/비웹 환경에서 다른 구현 사용
import 'platform_detector_io.dart' if (dart.library.html) 'platform_detector_stub.dart' as platform_impl;

/// 모바일 플랫폼인지 확인
bool isMobilePlatform() {
  if (kIsWeb) return false;
  return platform_impl.isMobilePlatform();
}

