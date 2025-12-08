// lib/core/widgets/responsive_text.dart

import "package:flutter/material.dart";
import "responsive_helper.dart";

/// 반응형 텍스트 위젯
/// 화면 크기에 따라 폰트 크기가 자동으로 조정됩니다.
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;

  const ResponsiveText({
    super.key,
    required this.text,
    required this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final fontSize = responsive.responsiveFontSize(
      mobileSize: mobileFontSize,
      tabletSize: tabletFontSize,
      desktopSize: desktopFontSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        color: color ?? style?.color,
        fontWeight: fontWeight ?? style?.fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

