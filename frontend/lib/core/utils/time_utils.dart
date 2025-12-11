// lib/core/utils/time_utils.dart

/// 시간 표시 유틸리티 함수
class TimeUtils {
  /// taken_at 기준으로 "{i}m ago", "{j}h ago", "{k}days ago" 형식으로 변환
  /// 
  /// 규칙:
  /// - 1 <= i <= 60: "{i}m ago"
  /// - 1 <= j <= 24: "{j}h ago"
  /// - 1 <= k: "{k}days ago"
  static String formatTimeAgo(DateTime takenAt) {
    final now = DateTime.now().toUtc();
    final takenAtUtc = takenAt.toUtc();
    final difference = now.difference(takenAtUtc);

    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;

    if (minutes < 1) {
      return "1m ago";
    } else if (minutes <= 60) {
      return "${minutes}m ago";
    } else if (hours <= 24) {
      return "${hours}h ago";
    } else {
      return "${days}days ago";
    }
  }
}

