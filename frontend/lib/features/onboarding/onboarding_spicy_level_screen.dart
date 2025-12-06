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

class _OnboardingSpicyLevelScreenState extends State<OnboardingSpicyLevelScreen>
    with SingleTickerProviderStateMixin {
  int _spicyLevel = 1; // 1~5 단계, 기본값은 1
  final int _totalSteps = 5;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // 각 단계별 라벨 (1, 3, 5번째만 표시)
  final Map<int, String> _levelLabels = {
    1: "아직\n어려워요",
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
        bottom: responsive.responsivePadding(mobilePadding: 0),
      ),
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
              "$userName님,\n맵기 레벨은 어디까지 가능하세요?",
              style: textTheme.headlineLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 26),
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 40),
            ),
            // 맵기 레벨 슬라이더
            _buildSpicyLevelSlider(responsive, textTheme),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpicyLevelSlider(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final circleRadius = 9.0; // 원의 반지름
    final circleDiameter = circleRadius * 2;
    final gaugeHeight = 4.0; // 게이지 바 높이
    final endMargin = 16.0; // 양 끝 여백

    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final padding = responsive.responsivePadding(mobilePadding: 20) * 2;
        final sliderWidth = screenWidth - padding;

        // 양 끝 여백을 제외한 사용 가능한 너비
        final availableWidth = sliderWidth - (endMargin * 2) - circleDiameter;
        // 각 원 사이의 거리
        final stepDistance = availableWidth / (_totalSteps - 1);

        // 각 원의 중심 위치 계산
        final circlePositions = List.generate(_totalSteps, (index) {
          return endMargin + circleRadius + (stepDistance * index);
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 게이지 바와 원을 포함한 전체 터치 영역
            SizedBox(
              width: sliderWidth,
              height: circleDiameter + 8, // 원이 게이지 위에 올라갈 공간
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final localPosition = details.localPosition.dx;
                  // 가장 가까운 원 찾기
                  int closestIndex = 0;
                  double minDistance = double.infinity;
                  for (int i = 0; i < circlePositions.length; i++) {
                    final distance = (localPosition - circlePositions[i]).abs();
                    if (distance < minDistance) {
                      minDistance = distance;
                      closestIndex = i;
                    }
                  }
                  final newStep = closestIndex + 1;

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
                  // 가장 가까운 원 찾기
                  int closestIndex = 0;
                  double minDistance = double.infinity;
                  for (int i = 0; i < circlePositions.length; i++) {
                    final distance = (localPosition - circlePositions[i]).abs();
                    if (distance < minDistance) {
                      minDistance = distance;
                      closestIndex = i;
                    }
                  }
                  final newStep = closestIndex + 1;

                  if (newStep != _spicyLevel) {
                    setState(() {
                      _spicyLevel = newStep;
                    });
                    _animationController.forward(from: 0.0);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 게이지 바 배경
                    Positioned(
                      left: 0,
                      top: circleRadius - gaugeHeight / 2,
                      child: Container(
                        width: sliderWidth,
                        height: gaugeHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEF3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    // 게이지 바 진행률
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        // 선택된 단계의 원 중심까지 진행률 표시
                        final progressWidth = circlePositions[_spicyLevel - 1];

                        return Positioned(
                          left: 0,
                          top: circleRadius - gaugeHeight / 2,
                          child: Container(
                            width: progressWidth,
                            height: gaugeHeight,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      },
                    ),
                    // 5개의 원 (게이지 바 위에 배치)
                    ...List.generate(_totalSteps, (index) {
                      final step = index + 1;
                      final isActive = _spicyLevel >= step;
                      final position = circlePositions[index];

                      return Positioned(
                        left: position - circleRadius,
                        top: 0,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final scale =
                                (step == _spicyLevel && _animation.value > 0)
                                    ? 1.0 + (_animation.value * 0.1)
                                    : 1.0;

                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: circleDiameter,
                                height: circleDiameter,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primary
                                        : const Color(0xFFF3EEF3),
                                    width: 2,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 12),
            ),
            // 라벨들 (1, 3, 5번째만 표시)
            IntrinsicHeight(
              child: SizedBox(
                width: sliderWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 각 단계 위치에 라벨 배치
                    ...List.generate(_totalSteps, (index) {
                      final step = index + 1;
                      final hasLabel = _levelLabels.containsKey(step);
                      final isActive = _spicyLevel >= step;
                      final position = circlePositions[index];

                      if (!hasLabel) return const SizedBox.shrink();

                      return Positioned(
                        left: position, // 원의 중심에 맞춤
                        top: 0,
                        child: Transform.translate(
                          offset: const Offset(-60, 0), // 라벨을 중앙 정렬하기 위한 오프셋
                          child: SizedBox(
                            width: 120,
                            child: Text(
                              _levelLabels[step]!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: responsive.responsiveFontSize(
                                    mobileSize: 12),
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.inactiveText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
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
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
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
