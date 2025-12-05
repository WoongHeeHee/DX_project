// lib/core/widgets/responsive_padding.dart

import "package:flutter/material.dart";
import "responsive_helper.dart";

/// 반응형 패딩 위젯
/// 화면 크기에 따라 패딩이 자동으로 조정됩니다.
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double mobilePadding;
  final double? tabletPadding;
  final double? desktopPadding;
  final EdgeInsets? mobileEdgeInsets;
  final EdgeInsets? tabletEdgeInsets;
  final EdgeInsets? desktopEdgeInsets;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding = 0,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileEdgeInsets,
    this.tabletEdgeInsets,
    this.desktopEdgeInsets,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    EdgeInsets padding;
    if (mobileEdgeInsets != null) {
      // EdgeInsets 직접 지정
      if (responsive.isMobile) {
        padding = mobileEdgeInsets!;
      } else if (responsive.isTablet) {
        padding = tabletEdgeInsets ?? mobileEdgeInsets! * 1.5;
      } else {
        padding = desktopEdgeInsets ?? mobileEdgeInsets! * 2.0;
      }
    } else {
      // 단일 값으로 패딩 계산
      final paddingValue = responsive.responsivePadding(
        mobilePadding: mobilePadding,
        tabletPadding: tabletPadding,
        desktopPadding: desktopPadding,
      );
      padding = EdgeInsets.all(paddingValue);
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

