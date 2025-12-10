// lib/features/onboarding/onboarding_loading_screen.dart

import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../data/repositories/api_repository.dart";

class OnboardingLoadingScreen extends StatefulWidget {
  final String? inputName;

  const OnboardingLoadingScreen({
    super.key,
    this.inputName,
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
    if (widget.inputName != null && widget.inputName!.isNotEmpty) {
      _generateKoreanName();
    } else {
      // inputName이 없으면 에러 처리
      debugPrint('에러: inputName이 없습니다.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이름을 입력해주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  Future<void> _generateKoreanName() async {
    try {
      // 한국 이름 생성 API 호출
      debugPrint("한국 이름 생성 요청: ${widget.inputName}");
      final koreanNameResponse =
          await _apiRepository.userService.generateKoreanName(widget.inputName!);

      debugPrint(
          "한국 이름 생성 응답: ${koreanNameResponse.koreanName}, ${koreanNameResponse.englishPronunciation}");

      if (koreanNameResponse.koreanName.isEmpty) {
        throw Exception("한국 이름이 생성되지 않았습니다.");
      }

      if (mounted) {
        // 로딩 완료 후 이름 확인 화면으로 이동 (extra로 데이터 전달)
        context.pushReplacement(
          "/onboarding/name-confirm",
          extra: {
            "inputName": widget.inputName,
            "koreanName": koreanNameResponse.koreanName,
            "englishPronunciation": koreanNameResponse.englishPronunciation,
          },
        );
      }
    } catch (e) {
      debugPrint("한국 이름 생성 에러: $e");
      if (mounted) {
        context.pop(); // 로딩 화면 닫기
        
        // 에러 메시지 생성
        String errorMessage = "한국 이름 생성에 실패했습니다.";
        
        // 연결 에러인 경우 더 명확한 메시지 표시
        if (e.toString().contains("서버에 연결할 수 없습니다") || 
            e.toString().contains("connection") ||
            e.toString().contains("Connection")) {
          errorMessage = "서버에 연결할 수 없습니다.\n서버가 실행 중인지 확인해주세요.\n\n자세한 내용은 SERVER_CONNECTION_GUIDE.md를 참조하세요.";
        } else if (e.toString().contains("timeout") || e.toString().contains("시간")) {
          errorMessage = "서버 응답 시간이 초과되었습니다.\n네트워크 연결과 서버 상태를 확인해주세요.";
        }
        
        // 에러 화면 대신 스낵바로 표시하고 재시도 가능하도록
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: "다시 시도",
              onPressed: () {
                // 이름 입력 화면으로 돌아가서 다시 시도
                context.pop();
              },
            ),
          ),
        );
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
