// lib/features/search/search_error_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/theme/app_colors.dart";

class SearchErrorScreen extends StatelessWidget {
  const SearchErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.softGreyBackground,
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
    return Padding(
      padding: EdgeInsets.all(
        responsive.responsivePadding(mobilePadding: 16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 644),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainContent(context, responsive, textTheme),
          ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
          _buildErrorMessage(responsive, textTheme),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
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
                  "죄송합니다\n음식을 찾을 수 없어요\n다시 시도해 주세요",
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.mainText,
                    fontSize: responsive.responsiveFontSize(mobileSize: 20),
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w500,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 11,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: ShapeDecoration(
              color: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleRetry(context),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "다시 입력하기",
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontSize: responsive.responsiveFontSize(mobileSize: 15),
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

