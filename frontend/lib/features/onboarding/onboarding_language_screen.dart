// lib/features/onboarding/onboarding_language_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../data/repositories/api_repository.dart";

class OnboardingLanguageScreen extends StatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  State<OnboardingLanguageScreen> createState() =>
      _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState
    extends State<OnboardingLanguageScreen> {
  String? _selectedLanguage; // 선택된 언어

  // 언어 옵션
  final List<LanguageOption> _languages = [
    LanguageOption(
      code: "ko",
      name: "Korean",
      greeting: "안녕하세요!\n한국어가 편하신가요?",
    ),
    LanguageOption(
      code: "en",
      name: "English",
      greeting: "Hello!\nDo you speak English?",
    ),
    LanguageOption(
      code: "zh",
      name: "Chinese",
      greeting: "你好！\n是中国人吗？",
    ),
    LanguageOption(
      code: "ja",
      name: "Japanese",
      greeting: "こんにちは！\n日本の方ですか？",
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 기본값: 한국어 선택
    _selectedLanguage = "ko";
  }

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
            Expanded(
              child: _buildContent(responsive, textTheme),
            ),
            // 하단 버튼
            _buildBottomButton(responsive, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ResponsiveHelper responsive) {
    const int totalSteps = 7;
    const int currentStep = 1;
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

  Widget _buildContent(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            // STEP 1 · Language
            Text(
              "STEP 1 · Language",
              style: textTheme.bodySmall?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 11),
                fontWeight: FontWeight.w400,
                color: AppColors.inactiveText,
                letterSpacing: 0.22,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            // 언어 선택 카드들
            Column(
              children: _languages.map((language) {
                final isSelected = _selectedLanguage == language.code;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: responsive.responsivePadding(mobilePadding: 10),
                  ),
                  child: _buildLanguageCard(
                    responsive,
                    textTheme,
                    language,
                    isSelected,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    LanguageOption language,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = language.code;
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 12),
          vertical: responsive.responsivePadding(mobilePadding: 14),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : const Color(0xFFF7F7F8),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary,
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.greeting,
              style: textTheme.titleMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 16),
                fontWeight: FontWeight.w500,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 4),
            ),
            Text(
              language.name,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 13),
                fontWeight: FontWeight.w400,
                color: AppColors.inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
        child: GestureDetector(
          onTap: () async {
            // locale 저장
            if (_selectedLanguage != null) {
              final apiRepository = ApiRepository();
              await apiRepository.userService.setLocale(_selectedLanguage!);
            }

            context.push('/onboarding/name');
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
            "선택 완료",
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

class LanguageOption {
  final String code;
  final String name;
  final String greeting;

  LanguageOption({
    required this.code,
    required this.name,
    required this.greeting,
  });
}

