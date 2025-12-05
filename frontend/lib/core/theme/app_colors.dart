// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // 1. 메인 브랜드 색상 (Main Brand Colors)
  static const Color primary = Color(0xFFFD312E); // 메인색상: #FD312E
  static const Color white = Color(0xFFFFFFFF); // 배경색: #FFFFFF (White)
  static const Color lightGrey = Color(0xFFF2F2F2); // 그레이박스: #F2F2F2

  // 2. 텍스트 및 서브 색상 (Text & Sub Colors)
  static const Color mainText = Color(0xFF222222); // 메인텍스트색상: #222222
  static const Color subText = Color(0xFF6C6C6C); // 서브텍스트: #6C6C6C

  // 3. 배경 및 카드 색상
  static const Color cardBackground = Color(0xFFF8FAFC); // 카드 배경색
  static const Color chipBackground = Color(0xFFF3F4F6); // 칩/필터 배경색
  static const Color imagePlaceholder = Color(0xFFF2F2F3); // 이미지 플레이스홀더

  // 4. 기타 색상
  static const Color black = Color(0xFF000000);
  static const Color inactiveText = Color(0xFF9CA3AF); // 비활성 텍스트
  static const Color filterColor = Color(0xFFFFB4B4); // 필터 색상 (일본 등)
}
