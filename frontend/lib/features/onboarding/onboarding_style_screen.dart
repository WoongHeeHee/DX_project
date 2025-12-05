// lib/features/onboarding/onboarding_style_screen.dart

import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/utils/onboarding_data.dart";
import "../../data/repositories/api_repository.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../core/widgets/error_screen.dart";
import "onboarding_complete_screen.dart";

class OnboardingStyleScreen extends StatefulWidget {
  final String? userName; // 사용자 이름
  final String? countryName; // 국가 이름
  final String? countryId; // 국가 ID (country_jp 등)
  final String? birthYyyyMm; // 생년월 (YYYY-MM)
  final int? spiceLevel; // 매운맛 레벨 (1-5)
  final String? locale; // locale (ko, en, zh, ja)

  const OnboardingStyleScreen({
    super.key,
    this.userName,
    this.countryName,
    this.countryId,
    this.birthYyyyMm,
    this.spiceLevel,
    this.locale,
  });

  @override
  State<OnboardingStyleScreen> createState() => _OnboardingStyleScreenState();
}

class _OnboardingStyleScreenState extends State<OnboardingStyleScreen> {
  String? _selectedStyle; // 선택된 스타일
  bool _isLoading = false;
  final _apiRepository = ApiRepository();

  // 스타일 옵션
  final List<String> _styles = [
    "신중하게 고민하는 편",
    "일단 시도하는 편",
    "잘 모르겠어요",
  ];

  @override
  void initState() {
    super.initState();
    // 기본값: 첫 번째 옵션 선택
    _selectedStyle = _styles[0];
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final userName = widget.userName ?? "김가희"; // 기본값

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
          children: [
            // 상단 진행률 인디케이터
            _buildProgressIndicator(responsive),
            // 메인 컨텐츠
            Expanded(
              child: _buildContent(responsive, textTheme, userName),
            ),
            // 하단 버튼
            _buildBottomButton(responsive, textTheme),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ResponsiveHelper responsive) {
    const int totalSteps = 8; // 총 8단계
    const int currentStep = 7; // 7단계 (한 칸만 더 가면 종료)
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
    String userName,
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
            // STEP 8 · Style
            Text(
              "STEP 8 · Style",
              style: textTheme.bodySmall?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 11),
                fontWeight: FontWeight.w400,
                color: AppColors.inactiveText,
                letterSpacing: 0.22,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 4),
            ),
            // 타이틀 (headlineLarge)
            Text(
              "$userName님,\n어떤 스타일이신가요?",
              style: textTheme.headlineLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 26),
                fontWeight: FontWeight.w600,
                height: 1,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            // 스타일 선택 옵션들
            _buildStyleOptions(responsive, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleOptions(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Column(
      children: _styles.map((style) {
        final isSelected = _selectedStyle == style;
        return Padding(
          padding: EdgeInsets.only(
            bottom: responsive.responsivePadding(mobilePadding: 10),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedStyle = style;
              });
            },
            child: Container(
              width: double.infinity,
              height: 56,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 12),
                vertical: responsive.responsivePadding(mobilePadding: 10),
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white : const Color(0xFFF7F7F8),
                border: isSelected
                    ? Border.all(
                        color: AppColors.primary,
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    style,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 14),
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.mainText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
            if (_selectedStyle == null) return;

            setState(() {
              _isLoading = true;
            });

            try {
              // 온보딩 완료 API 호출
              final countryCode = OnboardingData.getCountryCode(
                widget.countryId ?? 'country_jp',
              );
              final adventure = OnboardingData.getAdventureFromStyle(_selectedStyle!);
              final koreanExperience = OnboardingData.getKoreanExperience();

              await _apiRepository.userService.completeOnboarding(
                country: countryCode ?? 'JP',
                birthYyyyMm: widget.birthYyyyMm ?? '1990-01',
                spiceLevel: widget.spiceLevel ?? 3,
                adventure: adventure,
                koreanExperience: koreanExperience,
                locale: widget.locale ?? 'ko',
              );

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OnboardingCompleteScreen(
                      userName: widget.userName,
                      countryName: widget.countryName,
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ErrorScreen(
                      message: '온보딩 완료에 실패했습니다. 다시 시도해주세요.',
                      onRetry: () => Navigator.pop(context),
                    ),
                  ),
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.responsivePadding(mobilePadding: 16),
            vertical: responsive.responsivePadding(mobilePadding: 12),
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Enter",
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

