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
      mobileEdgeInsets: EdgeInsets.only(
        top: responsive.responsivePadding(mobilePadding: 16),
        bottom: responsive.responsivePadding(mobilePadding: 0),
      ),
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
      mobileEdgeInsets: EdgeInsets.only(
        left: responsive.responsivePadding(mobilePadding: 20),
        right: responsive.responsivePadding(mobilePadding: 20),
        top: responsive.responsivePadding(mobilePadding: 8),
        bottom: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 20),
          ),
          // STEP 2 · Name
          Text(
            "STEP 2 · Name",
            style: textTheme.bodySmall?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 16),
              fontWeight: FontWeight.w600,
              color: AppColors.inactiveText,
              letterSpacing: 0.22,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 40),
          ),
          // 타이틀 (headlineLarge)
          Text(
            "당신의 한국 이름입니다!",
            style: textTheme.headlineLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 26),
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: AppColors.mainText,
            ),
          ),
          // 중앙: 이름 결과값 (전체 화면의 정 중앙)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 한글 이름
                  Text(
                    "$_koreanName 님",
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 28),
                      fontWeight: FontWeight.w700,
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
                      fontSize: responsive.responsiveFontSize(mobileSize: 18),
                      fontWeight: FontWeight.w500,
                      color: AppColors.inactiveText,
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

  Widget _buildBottomButton(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobileEdgeInsets: EdgeInsets.only(
        top: responsive.responsivePadding(mobilePadding: 0),
        bottom: responsive.responsivePadding(mobilePadding: 40),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OnboardingCountryScreen(
                  userName: _koreanName,
                  inputName: widget.inputName,
                  koreanName: widget.koreanName,
                  englishPronunciation: widget.englishPronunciation,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            animationDuration: Duration.zero,
          ),
          child: Text(
            "Enter",
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
