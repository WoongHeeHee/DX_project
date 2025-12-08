import 'dart:io' show Directory, File;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 비웹 환경에서 사용되는 파일 헬퍼
Future<String?> findEnvFile() async {
  final currentDir = Directory.current.path;
  final appDocDir = await getApplicationDocumentsDirectory();

  final possiblePaths = [
    // 상대 경로
    '.env',
    'frontend/.env',
    // 절대 경로
    path.join(currentDir, '.env'),
    path.join(currentDir, 'frontend', '.env'),
    // 앱 문서 디렉토리 기반
    path.join(appDocDir.path, '..', '..', 'frontend', '.env'),
    path.join(appDocDir.path, '..', 'frontend', '.env'),
  ];

  for (final tryPath in possiblePaths) {
    try {
      final file = File(tryPath);
      if (await file.exists()) {
        return tryPath;
      }
    } catch (e) {
      continue;
    }
  }
  return null;
}

