// lib/features/map/widgets/back_button.dart

import "package:flutter/material.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/theme/app_colors.dart";

/// 지도 화면의 뒤로가기 버튼
class MapBackButton extends StatelessWidget {
  const MapBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(
          responsive.responsivePadding(mobilePadding: 16),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            width: responsive.responsiveIconSize(mobileSize: 40),
            height: responsive.responsiveIconSize(mobileSize: 40),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.mainText,
            ),
          ),
        ),
      ),
    );
  }
}

