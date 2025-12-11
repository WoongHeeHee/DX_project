// lib/features/onboarding/onboarding_loading_screen.dart

import "dart:async";
import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../data/repositories/api_repository.dart";
import "onboarding_name_confirm_screen.dart";

class OnboardingLoadingScreen extends StatefulWidget {
  final String inputName;

  const OnboardingLoadingScreen({
    super.key,
    required this.inputName,
  });

  @override
  State<OnboardingLoadingScreen> createState() =>
      _OnboardingLoadingScreenState();
}

class _OnboardingLoadingScreenState extends State<OnboardingLoadingScreen> {
  final _apiRepository = ApiRepository();

  @override
  void initState() {
    super.initState();

    // 화면이 로드되면 바로 API 호출
    _generateKoreanName();
  }

  Future<void> _generateKoreanName() async {
    try {
      // 한국 이름 생성 API 호출
      debugPrint('한국 이름 생성 요청: ${widget.inputName}');
      final koreanNameResponse =
          await _apiRepository.userService.generateKoreanName(widget.inputName);

      debugPrint(
          '한국 이름 생성 응답: ${koreanNameResponse.koreanName}, ${koreanNameResponse.englishPronunciation}');

      if (koreanNameResponse.koreanName.isEmpty) {
        throw Exception('한국 이름이 생성되지 않았습니다.');
      }

      if (mounted) {
        // 로딩 완료 후 이름 확인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingNameConfirmScreen(
              inputName: widget.inputName,
              koreanName: koreanNameResponse.koreanName,
              englishPronunciation: koreanNameResponse.englishPronunciation,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('한국 이름 생성 에러: $e');
      if (mounted) {
        // 에러 발생 시 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('한국 이름 생성에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // 에러 발생 시 이전 화면으로 돌아가기
        Navigator.pop(context);
      }
    }
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
            // 상단 진행률 인디케이터 (2단계 유지)
            _buildProgressIndicator(responsive),
            // 메인 컨텐츠 (중앙 정렬)
            Expanded(
              child: _buildContent(responsive, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ResponsiveHelper responsive) {
    const int totalSteps = 7;
    const int currentStep = 2; // 2단계 유지
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 40),
          ),
          Text(
            "･ ･ ･ 한국 이름을 만드는 중 ･ ･ ･",
            style: textTheme.bodyMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 14),
              fontWeight: FontWeight.w700,
              color: AppColors.mainText,
            ),
          ),
        ],
      ),
    );
  }
}
