// lib/features/onboarding/onboarding_complete_screen.dart

import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";

class OnboardingCompleteScreen extends StatefulWidget {
  final String? userName; // 한국 이름
  final String? countryName; // 국가 이름

  const OnboardingCompleteScreen({
    super.key,
    this.userName,
    this.countryName,
  });

  @override
  State<OnboardingCompleteScreen> createState() =>
      _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen> {
  @override
  void initState() {
    super.initState();
    // 5초 후 홈 화면으로 이동
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        context.go('/map');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final koreanName = widget.userName ?? "김가희"; // 한국 이름

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ResponsivePadding(
          mobilePadding: 16,
          tabletPadding: 24,
          desktopPadding: 32,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 환영 메시지
                Text(
                  "$koreanName 님의",
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 26),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: AppColors.mainText,
                  ),
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 20),
                ),
                // 이미지와 "을 위한" 텍스트 (같은 줄)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: responsive.responsiveFontSize(mobileSize: 180),
                      child: Image.asset(
                        "assets/designs/images/LGE_Electronics_Slogan.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(
                      width: responsive.responsivePadding(mobilePadding: 8),
                    ),
                    Text(
                      "을 위한",
                      textAlign: TextAlign.center,
                      style: textTheme.headlineLarge?.copyWith(
                        fontSize: responsive.responsiveFontSize(mobileSize: 26),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.mainText,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 20),
                ),
                // Sijang Go 텍스트
                Text(
                  "Sijang Go",
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 26),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: AppColors.mainText,
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

