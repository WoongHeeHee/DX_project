// lib/features/search/search_error_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";

class SearchErrorScreen extends StatelessWidget {
  const SearchErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _buildContent(context, responsive, textTheme),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: responsive.responsivePadding(mobilePadding: 8)),
          _buildMainContent(context, responsive, textTheme),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: responsive.responsivePadding(mobilePadding: 8)),
          _buildErrorMessage(responsive, textTheme),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          _buildRetryButton(context, responsive, textTheme),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "죄송합니다 음식을 찾을 수 없어요\n다시 시도해 주세요",
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.mainText,
                    fontSize: responsive.responsiveFontSize(mobileSize: 20),
                    fontWeight: FontWeight.w500,
                    height: 24.2 / 20, // Figma: lineHeight 24.2px / fontSize 20px
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton(
    BuildContext context,
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handleRetry(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.responsivePadding(mobilePadding: 16),
              vertical: responsive.responsivePadding(mobilePadding: 12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Text(
            "다시 입력하기",
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.white,
              fontSize: responsive.responsiveFontSize(mobileSize: 15),
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  void _handleRetry(BuildContext context) {
    // 라우터 기준으로 검색 화면으로 이동
    if (context.mounted) {
      context.go('/search');
    }
  }
}

