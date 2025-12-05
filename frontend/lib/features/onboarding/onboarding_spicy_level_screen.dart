// lib/features/onboarding/onboarding_spicy_level_screen.dart

import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "onboarding_style_screen.dart";

/// 온보딩 데이터 전달을 위한 클래스
class OnboardingData {
  final String? userName;
  final String? countryName;
  final String? countryId;
  final String? birthYyyyMm;
  final int? spiceLevel;
  final String? locale;

  OnboardingData({
    this.userName,
    this.countryName,
    this.countryId,
    this.birthYyyyMm,
    this.spiceLevel,
    this.locale,
  });
}

class OnboardingSpicyLevelScreen extends StatefulWidget {
  final String? userName; // 사용자 이름
  final String? countryName; // 국가 이름
  final String? countryId; // 국가 ID
  final String? birthYyyyMm; // 생년월

  const OnboardingSpicyLevelScreen({
    super.key,
    this.userName,
    this.countryName,
    this.countryId,
    this.birthYyyyMm,
  });

  @override
  State<OnboardingSpicyLevelScreen> createState() =>
      _OnboardingSpicyLevelScreenState();
}

class _OnboardingSpicyLevelScreenState
    extends State<OnboardingSpicyLevelScreen>
    with SingleTickerProviderStateMixin {
  int _spicyLevel = 1; // 1~5 단계, 기본값은 1
  final int _totalSteps = 5;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // 각 단계별 라벨 (1, 3, 5번째만 표시)
  final Map<int, String> _levelLabels = {
    1: "아직 어려워요",
    3: "김치",
    5: "불닭소스",
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final userName = widget.userName ?? "김가희"; // 기본값

    return Scaffold(
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
    );
  }

  Widget _buildProgressIndicator(ResponsiveHelper responsive) {
    const int totalSteps = 8; // 총 8단계
    const int currentStep = 7; // STEP 7
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
            // STEP 7 · Spicy Level
            Text(
              "STEP 7 · Spicy Level",
              style: textTheme.bodySmall?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 11),
                fontWeight: FontWeight.w500,
                color: AppColors.inactiveText,
                letterSpacing: 0.22,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 4),
            ),
            // 타이틀 (headlineLarge)
            Text(
              "$userName님,\n맵기 레벨은 어디까지\n가능하세요?",
              style: textTheme.headlineLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 26),
                fontWeight: FontWeight.w500,
                height: 1,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            // 맵기 레벨 슬라이더
            _buildSpicyLevelSlider(responsive, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSpicyLevelSlider(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        final handleSize = 32.0;
        final handleRadius = handleSize / 2;
        
        // 게이지 바는 전체 너비 사용, 불 이모티콘은 양쪽 끝에서 잘리지 않도록
        final availableWidth = sliderWidth - handleSize; // 불 이모티콘 크기만큼 여유 공간
        final stepWidth = availableWidth / (_totalSteps - 1);

        return Column(
          children: [
            // 불 이모티콘과 게이지 바를 포함한 전체 터치 영역
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                final localPosition = details.localPosition.dx;
                final newStep = ((localPosition / stepWidth).round() + 1)
                    .clamp(1, _totalSteps);
                
                if (newStep != _spicyLevel) {
                  setState(() {
                    _spicyLevel = newStep;
                  });
                  _animationController.forward(from: 0.0);
                }
              },
              onHorizontalDragEnd: (details) {
                _animationController.forward();
              },
              onTapDown: (details) {
                final localPosition = details.localPosition.dx;
                final newStep = ((localPosition / stepWidth).round() + 1)
                    .clamp(1, _totalSteps);
                
                if (newStep != _spicyLevel) {
                  setState(() {
                    _spicyLevel = newStep;
                  });
                  _animationController.forward(from: 0.0);
                }
              },
              child: Column(
                children: [
                  // 불 이모티콘 (게이지 바 위에 명확하게 표시)
                  SizedBox(
                    height: handleSize + 8, // 불 이모티콘을 위한 충분한 공간
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        // 불 이모티콘 위치: 각 단계에 맞춰 배치하되, 화면 안에 있도록
                        final handlePosition = stepWidth * (_spicyLevel - 1);
                        
                        return Stack(
                          children: [
                            // 불 이모티콘 (드래그 가능한 핸들)
                            Positioned(
                              left: handlePosition.clamp(0.0, availableWidth), // 화면 안에 있도록 clamp
                              top: 4,
                              child: Transform.scale(
                                scale: 1.0 + (_animation.value * 0.1),
                                child: Container(
                                  width: handleSize,
                                  height: handleSize,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "🔥",
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 게이지 바
                  Stack(
                    children: [
                      // 게이지 바 배경
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEF3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      // 게이지 바 진행률
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final progressWidth = stepWidth * (_spicyLevel - 1) + handleRadius;
                          
                          return Container(
                            width: progressWidth.clamp(0.0, sliderWidth),
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        },
                      ),
                      // 각 단계 위치에 점 표시 (터치 가이드)
                      ...List.generate(_totalSteps, (index) {
                        final step = index + 1;
                        final position = stepWidth * (step - 1) + handleRadius;
                        return Positioned(
                          left: position - 4,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: step <= _spicyLevel
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 8),
            ),
            // 라벨들 (1, 3, 5번째만 표시)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_totalSteps, (index) {
                final step = index + 1;
                final hasLabel = _levelLabels.containsKey(step);
                final isActive = _spicyLevel >= step;
                final handleSize = 32.0;
                final sliderWidth = constraints.maxWidth;
                final availableWidth = sliderWidth - handleSize;
                final stepWidth = availableWidth / (_totalSteps - 1);

                return SizedBox(
                  width: stepWidth,
                  child: Column(
                    children: [
                      // 점 (모든 단계에 표시)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : const Color(0xFFF3EEF3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // 라벨 (1, 3, 5번째만)
                      if (hasLabel)
                        Padding(
                          padding: EdgeInsets.only(
                            top: responsive.responsivePadding(mobilePadding: 4),
                          ),
                          child: Text(
                            _levelLabels[step]!,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: responsive.responsiveFontSize(mobileSize: 10),
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.inactiveText,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OnboardingStyleScreen(
                  userName: widget.userName,
                  countryName: widget.countryName,
                  countryId: widget.countryId,
                  birthYyyyMm: widget.birthYyyyMm,
                  spiceLevel: _spicyLevel,
                  locale: null, // TODO: locale 전달 필요 (언어 선택 화면에서)
                ),
              ),
            );
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

