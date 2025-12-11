// lib/features/map/widgets/action_buttons.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/widgets/responsive_padding.dart";
import "../../../core/theme/app_colors.dart";
import "../../home/models/market_model.dart";

/// 액션 버튼 위젯 (메뉴 설명 보기, 가게 보기)
class ActionButtons extends StatelessWidget {
  final MarketModel market;

  const ActionButtons({
    super.key,
    required this.market,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 47,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.responsivePadding(mobilePadding: 12),
              vertical: responsive.responsivePadding(mobilePadding: 10),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: responsive.responsiveIconSize(mobileSize: 18),
                  color: AppColors.mainText,
                ),
                SizedBox(
                  width: responsive.responsivePadding(mobilePadding: 10),
                ),
                Text(
                  "떡볶이 메뉴 설명 보기",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.mainText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 8)),
          GestureDetector(
            onTap: () {
              context.push(
                '/map/market/${market.id}/store-list',
                extra: {
                  'market': market,
                  'menuName': "떡볶이", // TODO: 실제 선택된 메뉴명으로 변경
                },
              );
            },
            child: Container(
              width: double.infinity,
              height: 47,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 12),
                vertical: responsive.responsivePadding(mobilePadding: 10),
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store,
                    size: responsive.responsiveIconSize(mobileSize: 18),
                    color: AppColors.white,
                  ),
                  SizedBox(
                    width: responsive.responsivePadding(mobilePadding: 10),
                  ),
                  Text(
                    "${market.name} 안 떡볶이 가게 보기",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

