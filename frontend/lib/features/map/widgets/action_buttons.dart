// lib/features/map/widgets/action_buttons.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/widgets/responsive_padding.dart";
import "../../../core/theme/app_colors.dart";
import "../../../data/models/menu_models.dart";
import "../../home/models/market_model.dart";
import "../../home/models/food_model.dart";

/// 액션 버튼 위젯 (메뉴 설명 보기, 가게 보기)
class ActionButtons extends StatelessWidget {
  final MarketModel market;
  final MenuItemModel? selectedMenuItem;
  final FoodModel? selectedFood;
  final bool isLoading;

  const ActionButtons({
    super.key,
    required this.market,
    this.selectedMenuItem,
    this.selectedFood,
    this.isLoading = false,
  });

  String _getMenuName() {
    if (isLoading) {
      return "...";
    }
    return selectedMenuItem?.name ?? "떡볶이";
  }

  void _navigateToMenuDetail(BuildContext context) {
    if (selectedFood == null) return;
    context.push('/explore/food/${selectedFood!.id}', extra: {'food': selectedFood});
  }

  void _navigateToStoreList(BuildContext context) {
    final menuName = _getMenuName();
    // 디버깅: 전달되는 메뉴 이름 확인
    debugPrint("[ActionButtons] Find Shops 버튼 클릭: menuName='$menuName', selectedMenuItem?.name='${selectedMenuItem?.name}', selectedMenuItem?.id='${selectedMenuItem?.id}'");
    context.push(
      '/map/market/${market.id}/store-list',
      extra: {
        'market': market,
        'menuName': menuName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final menuName = _getMenuName();

    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        children: [
          GestureDetector(
            onTap: selectedMenuItem != null ? () => _navigateToMenuDetail(context) : null,
            child: Container(
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
                    "View $menuName Details",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 8)),
          GestureDetector(
            onTap: () => _navigateToStoreList(context),
            child: Container(
              width: double.infinity,
              height: responsive.responsiveIconSize(mobileSize: 47),
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
                    "Find $menuName Shops",
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

