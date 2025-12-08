import 'dart:io' show Platform;

/// 비웹 환경에서 사용되는 플랫폼 감지
bool isMobilePlatform() {
  return !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS;
}
