// lib/features/my/gift_popup_dialog.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "coupon_detail_screen.dart";

class GiftPopupDialog extends StatelessWidget {
  final VoidCallback? onShowFloatingButton;

  const GiftPopupDialog({
    super.key,
    this.onShowFloatingButton,
  });

  static void show(
    BuildContext context, {
    VoidCallback? onShowFloatingButton,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GiftPopupDialog(
        onShowFloatingButton: onShowFloatingButton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: Container(
        padding: EdgeInsets.all(
          responsive.responsivePadding(mobilePadding: 24),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘과 제목
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 선물 상자 아이콘
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                SizedBox(
                  width: responsive.responsivePadding(mobilePadding: 12),
                ),
                // 텍스트들
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "특별한 선물이 도착했어요!",
                        style: textTheme.titleLarge?.copyWith(
                          fontSize:
                              responsive.responsiveFontSize(mobileSize: 18),
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainText,
                        ),
                      ),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 4),
                      ),
                      Text(
                        "SijangGO가 준비한 힐링 타임",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize:
                              responsive.responsiveFontSize(mobileSize: 14),
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainText,
                        ),
                      ),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 4),
                      ),
                      Text(
                        "[LG전자 리프레시룸 체험권] 당첨!",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize:
                              responsive.responsiveFontSize(mobileSize: 14),
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 24),
            ),
            // 더 보기 버튼 (메인컬러)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CouponDetailScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.responsivePadding(mobilePadding: 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  "더 보기",
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 12),
            ),
            // 닫기 버튼 (회색)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onShowFloatingButton?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.responsivePadding(mobilePadding: 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  "닫기",
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

