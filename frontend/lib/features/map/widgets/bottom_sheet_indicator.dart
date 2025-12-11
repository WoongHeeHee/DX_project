// lib/features/map/widgets/bottom_sheet_indicator.dart

import "package:flutter/material.dart";
import "../../../core/theme/app_colors.dart";

/// 바텀시트 인디케이터 위젯
class BottomSheetIndicator extends StatelessWidget {
  const BottomSheetIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.subText.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

