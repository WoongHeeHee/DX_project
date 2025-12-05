// lib/core/widgets/responsive_container.dart

import "package:flutter/material.dart";
import "responsive_helper.dart";

/// 반응형 컨테이너 위젯
/// 화면 크기에 따라 패딩, 마진, 최대 너비가 자동으로 조정됩니다.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobilePadding;
  final double? tabletPadding;
  final double? desktopPadding;
  final double? mobileMargin;
  final double? tabletMargin;
  final double? desktopMargin;
  final double? maxWidth;
  final Color? color;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileMargin,
    this.tabletMargin,
    this.desktopMargin,
    this.maxWidth,
    this.color,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    double? padding;
    if (mobilePadding != null) {
      padding = responsive.responsivePadding(
        mobilePadding: mobilePadding!,
        tabletPadding: tabletPadding,
        desktopPadding: desktopPadding,
      );
    }

    double? margin;
    if (mobileMargin != null) {
      margin = responsive.responsiveMargin(
        mobileMargin: mobileMargin!,
        tabletMargin: tabletMargin,
        desktopMargin: desktopMargin,
      );
    }

    final containerWidth = maxWidth != null
        ? responsive.getMaxContainerWidth(maxWidth!)
        : null;

    Widget content = Container(
      width: containerWidth,
      padding: padding != null ? EdgeInsets.all(padding) : null,
      margin: margin != null ? EdgeInsets.all(margin) : null,
      color: color,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );

    // 데스크톱에서 최대 너비가 설정된 경우 중앙 정렬
    if (containerWidth != null && responsive.isDesktop) {
      content = Center(child: content);
    }

    return content;
  }
}

