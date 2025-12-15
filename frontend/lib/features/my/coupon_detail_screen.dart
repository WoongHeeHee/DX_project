// lib/features/my/coupon_detail_screen.dart

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";

class CouponDetailScreen extends StatelessWidget {
  final String couponCode;

  const CouponDetailScreen({
    super.key,
    this.couponCode = "dnzeuzpu74ulj",
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.responsivePadding(mobilePadding: 20),
              vertical: responsive.responsivePadding(mobilePadding: 40),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 40),
                ),
                // 온보딩 완료 이미지
                SizedBox(
                  width: responsive.responsiveFontSize(mobileSize: 180),
                  child: Image.asset(
                    "assets/designs/images/LGE_Electronics_Slogan.png",
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 32),
                ),
                // 대제목
                Text(
                  "LG전자 리프레시룸 체험권",
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 24),
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainText,
                  ),
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 24),
                ),
                // 쿠폰 번호 안내
                Text(
                  "당신의 쿠폰 번호는",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 16),
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainText,
                  ),
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 8),
                ),
                // 쿠폰 번호
                Text(
                  "'$couponCode' 입니다!",
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 18),
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainText,
                  ),
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 40),
                ),
                // 쿠폰 번호 복사하기 버튼 (회색)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: couponCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("쿠폰 번호가 복사되었습니다"),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F3F3),
                      foregroundColor: AppColors.mainText,
                      padding: EdgeInsets.symmetric(
                        vertical:
                            responsive.responsivePadding(mobilePadding: 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      "쿠폰 번호 복사하기",
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: responsive.responsiveFontSize(mobileSize: 16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainText,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 12),
                ),
                // 예약하러 가기 버튼 (메인컬러)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: LG전자 리프레시룸 예약 페이지로 이동
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        vertical:
                            responsive.responsivePadding(mobilePadding: 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      "LG전자 리프레시룸\n예약하러 가기",
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: responsive.responsiveFontSize(mobileSize: 16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

