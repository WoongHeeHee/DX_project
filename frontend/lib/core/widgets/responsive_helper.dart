// lib/core/widgets/responsive_helper.dart

import "package:flutter/material.dart";
import "../constants/breakpoints.dart";

/// 반응형 디자인을 위한 헬퍼 클래스
/// MediaQuery를 활용하여 화면 크기에 따른 동적 값 계산
class ResponsiveHelper {
  final BuildContext context;
  final MediaQueryData mediaQuery;

  ResponsiveHelper(this.context) : mediaQuery = MediaQuery.of(context);

  /// 현재 화면 너비
  double get width => mediaQuery.size.width;

  /// 현재 화면 높이
  double get height => mediaQuery.size.height;

  /// 화면 너비의 비율 (0.0 ~ 1.0)
  double widthRatio(double ratio) => width * ratio;

  /// 화면 높이의 비율 (0.0 ~ 1.0)
  double heightRatio(double ratio) => height * ratio;

  /// 모바일 여부
  bool get isMobile => width < Breakpoints.mobile;

  /// 태블릿 여부
  bool get isTablet =>
      width >= Breakpoints.mobile && width < Breakpoints.tablet;

  /// 데스크톱 여부
  bool get isDesktop => width >= Breakpoints.tablet;

  /// 화면 크기 타입 반환
  ScreenSize get screenSize {
    if (isMobile) return ScreenSize.mobile;
    if (isTablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// 반응형 폰트 크기 계산
  /// [mobileSize]: 모바일 기본 크기
  /// [tabletSize]: 태블릿 크기 (기본값: mobileSize * 1.2)
  /// [desktopSize]: 데스크톱 크기 (기본값: mobileSize * 1.5)
  double responsiveFontSize({
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isMobile) return mobileSize;
    if (isTablet) return tabletSize ?? mobileSize * 1.2;
    return desktopSize ?? mobileSize * 1.5;
  }

  /// 반응형 패딩 계산
  /// [mobilePadding]: 모바일 기본 패딩
  /// [tabletPadding]: 태블릿 패딩 (기본값: mobilePadding * 1.5)
  /// [desktopPadding]: 데스크톱 패딩 (기본값: mobilePadding * 2.0)
  double responsivePadding({
    required double mobilePadding,
    double? tabletPadding,
    double? desktopPadding,
  }) {
    if (isMobile) return mobilePadding;
    if (isTablet) return tabletPadding ?? mobilePadding * 1.5;
    return desktopPadding ?? mobilePadding * 2.0;
  }

  /// 반응형 마진 계산
  double responsiveMargin({
    required double mobileMargin,
    double? tabletMargin,
    double? desktopMargin,
  }) {
    if (isMobile) return mobileMargin;
    if (isTablet) return tabletMargin ?? mobileMargin * 1.5;
    return desktopMargin ?? mobileMargin * 2.0;
  }

  /// 반응형 아이콘 크기 계산
  double responsiveIconSize({
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isMobile) return mobileSize;
    if (isTablet) return tabletSize ?? mobileSize * 1.2;
    return desktopSize ?? mobileSize * 1.5;
  }

  /// 최대 컨테이너 너비 계산 (데스크톱에서 중앙 정렬용)
  /// [maxWidth]: 최대 너비 (기본값: 1200)
  double getMaxContainerWidth([double maxWidth = 1200]) {
    if (isDesktop) {
      return width > maxWidth ? maxWidth : width;
    }
    return width;
  }

  /// 반응형 컬럼 개수 계산 (그리드 레이아웃용)
  /// [mobileColumns]: 모바일 컬럼 수
  /// [tabletColumns]: 태블릿 컬럼 수
  /// [desktopColumns]: 데스크톱 컬럼 수
  int responsiveColumns({
    required int mobileColumns,
    required int tabletColumns,
    required int desktopColumns,
  }) {
    if (isMobile) return mobileColumns;
    if (isTablet) return tabletColumns;
    return desktopColumns;
  }
}

/// 화면 크기 타입 열거형
enum ScreenSize {
  mobile,
  tablet,
  desktop,
}

/// BuildContext 확장 메서드로 ResponsiveHelper 쉽게 접근
extension ResponsiveExtension on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}

