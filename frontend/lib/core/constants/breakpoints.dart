// lib/core/constants/breakpoints.dart

/// 화면 크기 브레이크포인트 정의
/// 모바일, 태블릿, 데스크톱을 구분하기 위한 기준값
class Breakpoints {
  // 화면 너비 기준 (단위: logical pixels)
  static const double mobile = 600; // 모바일: ~600px
  static const double tablet = 900; // 태블릿: 601px ~ 900px
  // 데스크톱: 901px 이상

  // 화면 높이 기준 (선택적 사용)
  static const double shortHeight = 600; // 짧은 화면
  static const double tallHeight = 900; // 긴 화면
}

