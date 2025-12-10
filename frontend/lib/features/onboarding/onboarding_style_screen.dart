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
      mobileEdgeInsets: EdgeInsets.only(
        left: responsive.responsivePadding(mobilePadding: 20),
        right: responsive.responsivePadding(mobilePadding: 20),
        top: responsive.responsivePadding(mobilePadding: 8),
        bottom: responsive.responsivePadding(mobilePadding: 20),
      ),
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
              "$userName님,\n어떤 스타일이신가요?",
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
    final textSize = responsive.responsiveFontSize(mobileSize: 16);

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
              padding: EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 12),
                vertical: responsive.responsivePadding(mobilePadding: 28),
              ),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
                border: isSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFFF7F7F8),
                        width: 1,
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    style,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: textSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainText,
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
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () async {
            if (_selectedStyle == null) return;

            setState(() {
              _isLoading = true;
            });

            try {
              // 온보딩 완료 API 호출
              final countryCode = OnboardingData.getCountryCode(
                widget.countryId ?? 'country_jp',
              );
              final adventure =
                  OnboardingData.getAdventureFromStyle(_selectedStyle!);
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

