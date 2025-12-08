// lib/features/report/report_guide_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";

class ReportGuideScreen extends StatelessWidget {
  const ReportGuideScreen({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 뒤로가기 버튼
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
                color: AppColors.mainText,
              ),
              SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
              // 제목
              Text(
                "가게 제보하기",
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 26),
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
              ),
              SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
              // 안내 문구
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "프로젝트 설명",
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: responsive.responsiveFontSize(mobileSize: 18),
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainText,
                        ),
                      ),
                      SizedBox(height: responsive.responsivePadding(mobilePadding: 12)),
                      Text(
                        "Apex 시장은 전국 시장의 최신 정보를 제공하는 서비스입니다.\n"
                        "여러분이 직접 촬영한 사진을 통해 시장의 생생한 정보를 공유해주세요.",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: responsive.responsiveFontSize(mobileSize: 14),
                          color: AppColors.subText,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: responsive.responsivePadding(mobilePadding: 24)),
                      Text(
                        "제보 안내",
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: responsive.responsiveFontSize(mobileSize: 18),
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainText,
                        ),
                      ),
                      SizedBox(height: responsive.responsivePadding(mobilePadding: 12)),
                      _buildGuideItem(
                        responsive,
                        textTheme,
                        "1. 위치 권한 허용",
                        "현재 위치를 확인하여 주변 가게를 찾습니다.",
                      ),
                      SizedBox(height: responsive.responsivePadding(mobilePadding: 12)),
                      _buildGuideItem(
                        responsive,
                        textTheme,
                        "2. 사진 촬영",
                        "가게 사진을 촬영해주세요.",
                      ),
                      SizedBox(height: responsive.responsivePadding(mobilePadding: 12)),
                      _buildGuideItem(
                        responsive,
                        textTheme,
                        "3. 가게 선택",
                        "촬영한 위치 주변의 가게를 선택해주세요.",
                      ),
                    ],
                  ),
                ),
              ),
              // 촬영 시작 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // 위치 및 카메라 권한 요청
                    // TODO: 실제 권한 요청 로직 구현
                    context.push('/report/camera');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.responsivePadding(mobilePadding: 16),
                    ),
                  ),
                  child: Text(
                    "촬영 시작",
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideItem(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            size: 16,
            color: AppColors.white,
          ),
        ),
        SizedBox(width: responsive.responsivePadding(mobilePadding: 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
              ),
              SizedBox(height: responsive.responsivePadding(mobilePadding: 4)),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 14),
                  color: AppColors.subText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

