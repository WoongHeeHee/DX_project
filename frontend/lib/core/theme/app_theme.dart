// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

// 💡 앱 전체의 디자인 데이터를 담는 final 변수
final ThemeData appTheme = ThemeData(
  // ----------------------------------------------------
  // 1. 기본 설정 및 폰트
  // ----------------------------------------------------
  useMaterial3: true,
  brightness: Brightness.light, // 기본 밝기 (라이트 모드)
  // pubspec.yaml에 등록한 폰트 패밀리를 앱 전체 기본 폰트로 지정합니다.
  fontFamily: 'NotoSansKR',

  // 다국어 지원을 위한 폰트 Fallback 순서를 지정합니다.
  fontFamilyFallback: const ['NotoSansJP', 'NotoSansSC', 'NotoSans'],

  // ----------------------------------------------------
  // 2. 색상 구성표 (Color Scheme)
  // ----------------------------------------------------
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary, // 메인 색상을 시드(Seed)로 사용
    primary: AppColors.primary,
    onPrimary: AppColors.white, // primary 위에 올라가는 색상 (대부분 흰색)
    secondary: AppColors.primary, // 강조색도 primary와 동일하게 설정
    surface: AppColors.white, // 카드나 배경 위에 올라가는 컴포넌트 색상
    error: const Color(0xFFB00020), // 에러 발생 시 사용될 색상
  ),

  // 화면 배경색 지정 (Scaffold의 기본 배경색)
  scaffoldBackgroundColor: AppColors.white,

  // 호버/터치 시 생기는 원형 효과 제거
  splashFactory: NoSplash.splashFactory,

  // ----------------------------------------------------
  // 3. 텍스트 테마 (TextTheme)
  // ----------------------------------------------------
  textTheme: const TextTheme(
    // 1. 헤드라인 (Headline)
    headlineLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600, // Semi Bold
      color: AppColors.mainText,
    ),

    // 2. 타이틀 (Title)
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600, // Semi Bold
      color: AppColors.mainText,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700, // Bold
      color: AppColors.mainText,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500, // Medium
      color: AppColors.mainText,
    ),

    // 3. 본문 (Body)
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400, // Regular
      color: AppColors.mainText,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400, // Regular
      color: AppColors.mainText,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400, // Regular
      color: AppColors.subText,
    ),

    // 4. 라벨 (Label)
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600, // Semi Bold
      color: AppColors.white, // 버튼 텍스트는 보통 흰색
    ),
    labelMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500, // Medium
      color: AppColors.mainText,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400, // Regular
      color: AppColors.subText,
    ),
  ),

  // ----------------------------------------------------
  // 4. 위젯 테마 (Button/App Bar 등)
  // ----------------------------------------------------

  // ElevatedButton 기본 스타일 정의
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: AppColors.white, // 텍스트 색상
      backgroundColor: AppColors.primary, // 버튼 배경색
      minimumSize: const Size(double.infinity, 50), // 버튼 최소 크기 (가로 꽉 참, 높이 50)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 모서리 둥글기
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'NotoSansKR',
      ),
    ),
  ),

  // lib/core/theme/app_theme.dart의 ThemeData 내부
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.mainText, // 기본 텍스트 색상
      backgroundColor: AppColors.lightGrey, // 버튼 배경색

      minimumSize: const Size(double.infinity, 50), // ElevatedButton과 높이를 통일
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      // 텍스트 스타일은 labelLarge를 기반으로 정의 (AppTheme에서 폰트 패밀리 자동 상속)
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600, // Semi Bold
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    // 텍스트 필드의 배경색을 lightGrey로 설정 (예: 검색창)
    fillColor: AppColors.lightGrey,
    filled: true,

    // 외곽선 스타일 (Focused: 활성화/입력 중일 때)
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary, width: 2), // 메인 색상 테두리
      borderRadius: BorderRadius.circular(8),
    ),

    // 기본 외곽선 스타일 (Disabled: 비활성화 상태)
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.lightGrey, width: 1), // 연한 회색 테두리
      borderRadius: BorderRadius.circular(8),
    ),

    // 힌트 텍스트 스타일
    hintStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.subText,
    ),

    // 내부 패딩 설정 (필드 안의 텍스트 여백)
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),

  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.white, // 배경색 (보통 흰색)
    selectedItemColor: AppColors.primary, // 선택된 아이콘/텍스트 색상
    unselectedItemColor: AppColors.subText, // 선택되지 않은 아이콘/텍스트 색상
    // 텍스트 스타일은 labelSmall을 기반으로 정의할 수 있습니다.
    selectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.w600, // Semi Bold
      fontSize: 10,
    ),
    unselectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.w500, // Medium
      fontSize: 10,
    ),

    elevation: 4, // 상단에 약간의 그림자 추가
    type: BottomNavigationBarType.fixed, // 탭이 4개 이상일 때도 고정 유지
  ),

  // AppBar 기본 스타일 정의
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.mainText,
    elevation: 0, // 그림자 없애기
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      fontFamily: 'NotoSansKR',
      color: AppColors.mainText,
    ),
  ),
);
