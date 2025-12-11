// lib/features/map/widgets/feed_header.dart

import "package:flutter/material.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/widgets/responsive_padding.dart";
import "../../../core/theme/app_colors.dart";

/// 피드 헤더 위젯 (NOW 탭의 필터 포함)
class FeedHeader extends StatelessWidget {
  final String marketName;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const FeedHeader({
    super.key,
    required this.marketName,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: responsive.responsivePadding(mobilePadding: 12),
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$marketName NOW",
              style: textTheme.titleMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 16),
                fontWeight: FontWeight.w500,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
            // 필터 칩들
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["전체", "식사", "간식", "디저트", "음료"].map((filter) {
                  final isSelected = selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      onFilterChanged(filter);
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        right: responsive.responsivePadding(mobilePadding: 6),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.responsivePadding(
                          mobilePadding: 12,
                        ),
                        vertical: responsive.responsivePadding(
                          mobilePadding: 10,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        filter,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: responsive.responsiveFontSize(
                            mobileSize: 12,
                          ),
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

