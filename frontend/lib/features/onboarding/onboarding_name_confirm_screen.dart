// lib/features/onboarding/onboarding_name_confirm_screen.dart

import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "onboarding_country_screen.dart";

class OnboardingNameConfirmScreen extends StatefulWidget {
  final String? inputName; // 입력된 이름
  final String? koreanName; // 생성된 한국 이름
  final String? englishPronunciation; // 영어 발음

  const OnboardingNameConfirmScreen({
    super.key,
    this.inputName,
    this.koreanName,
    this.englishPronunciation,
  });

  @override
  State<OnboardingNameConfirmScreen> createState() =>
      _OnboardingNameConfirmScreenState();
}

class _OnboardingNameConfirmScreenState
    extends State<OnboardingNameConfirmScreen> {
  String get _koreanName => widget.koreanName ?? widget.inputName ?? "김가희";
  String get _englishName => widget.englishPronunciation ?? "Kim Ga-hee";

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 진행률 인디케이터
            _buildProgressIndicator(responsive),
            // 메인 컨텐츠
            Expanded(child: _buildContent(responsive, textTheme)),
            // 하단 버튼
            _buildBottomButton(responsive, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ResponsiveHelper responsive) {
    const int totalSteps = 7;
    const int currentStep = 2; // STEP 2 유지
    final double progress = currentStep / totalSteps;

    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double containerWidth = constraints.maxWidth;
          final double progressWidth = containerWidth * progress;

          return Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEF3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: progressWidth,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
            // STEP 2 · Name
            Text(
              "STEP 2 · Name",
              style: textTheme.bodySmall?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 11),
                fontWeight: FontWeight.w400,
                color: AppColors.inactiveText,
                letterSpacing: 0.22,
              ),
            ),
            SizedBox(height: responsive.responsivePadding(mobilePadding: 4)),
            // 타이틀 (headlineLarge)
            Text(
              "당신의 이름은 무엇인가요?",
              style: textTheme.headlineLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 26),
                fontWeight: FontWeight.w500,
                height: 1,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
            // 이름 표시 영역 (중앙 정렬)
            SizedBox(
              height: 256,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 이모지들
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "🎉",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: responsive.responsiveFontSize(
                            mobileSize: 18,
                          ),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(
                        width: responsive.responsivePadding(mobilePadding: 40),
                      ),
                      Text(
                        "🎉",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: responsive.responsiveFontSize(
                            mobileSize: 18,
                          ),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: responsive.responsivePadding(mobilePadding: 12),
                  ),
                  // 한글 이름
                  Text(
                    "$_koreanName 님",
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 24),
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainText,
                    ),
                  ),
                  SizedBox(
                    height: responsive.responsivePadding(mobilePadding: 2),
                  ),
                  // 영문 이름
                  Text(
                    _englishName,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.inactiveText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OnboardingCountryScreen(userName: _koreanName),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: responsive.responsivePadding(mobilePadding: 13),
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "enter",
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 15),
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
