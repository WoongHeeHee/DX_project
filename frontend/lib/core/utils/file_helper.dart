import 'package:flutter/foundation.dart';

/// 파일 시스템 접근을 위한 헬퍼
/// 조건부 import를 사용하여 웹/비웹 환경에서 다른 구현 사용
import 'file_helper_io.dart' if (dart.library.html) 'file_helper_stub.dart' as file_impl;

/// .env 파일 경로 찾기
Future<String?> findEnvFile() async {
  if (kIsWeb) {
    return null; // 웹에서는 .env 파일을 파일 시스템에서 읽을 수 없음
  }
  return file_impl.findEnvFile();
}

