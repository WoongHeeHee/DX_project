// lib/features/report/report_complete_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";

class ReportCompleteScreen extends StatelessWidget {
  const ReportCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ResponsivePadding(
          mobilePadding: 16,
          tabletPadding: 24,
          desktopPadding: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 완료 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: responsive.responsivePadding(mobilePadding: 24)),
              // 완료 메시지
              Text(
                "제보가 완료되었습니다!",
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 24),
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.responsivePadding(mobilePadding: 12)),
              Text(
                "제보해주신 정보는 검토 후\n서비스에 반영됩니다.",
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 14),
                  color: AppColors.subText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.responsivePadding(mobilePadding: 40)),
              // 홈으로 돌아가기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/explore');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.responsivePadding(mobilePadding: 16),
                    ),
                  ),
                  child: Text(
                    "홈으로 돌아가기",
                    style: textTheme.labelLarge?.copyWith(
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
    );
  }
}

