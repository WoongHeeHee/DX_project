// lib/features/onboarding/onboarding_complete_screen.dart

import "dart:async";
import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/main_navigation.dart";

class OnboardingCompleteScreen extends StatefulWidget {
  final String? userName; // 사용자 이름
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

class _OnboardingCompleteScreenState
    extends State<OnboardingCompleteScreen> {
  @override
  void initState() {
    super.initState();
    // 5초 후 홈화면으로 이동
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final userName = widget.userName ?? "김가희"; // 기본값
    final countryName = widget.countryName ?? "일본"; // 기본값

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
                // 로고 이미지
                Container(
                  width: 188,
                  height: 43,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: NetworkImage("https://placehold.co/188x43"),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 20),
                ),
                // 환영 메시지
                Text(
                  "$userName 님의\n$countryName 을 위한\nSijangGO",
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 30),
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainText,
                    height: 1.2,
                  ),
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 20),
                ),
                // 회색 박스 (로고 또는 이미지 영역)
                Container(
                  width: 86,
                  height: 33,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 20),
                ),
                // 안내 메시지
                Text(
                  "온보딩이 완료되면 홈으로 진입합니다.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 11),
                    fontWeight: FontWeight.w500,
                    color: AppColors.inactiveText,
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

