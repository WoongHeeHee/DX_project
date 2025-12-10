// lib/features/onboarding/onboarding_loading_screen.dart

import "dart:async";
import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
// import "../../data/repositories/api_repository.dart"; // TODO: 서버 연결 시 주석 해제
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
  // final _apiRepository = ApiRepository(); // TODO: 서버 연결 시 주석 해제

  @override
  void initState() {
    super.initState();

    // 화면이 로드되면 바로 API 호출
    _generateKoreanName();
  }

  Future<void> _generateKoreanName() async {
    try {
      // TODO: 서버 연결 시 주석 해제
      // // 한국 이름 생성 API 호출
      // debugPrint('한국 이름 생성 요청: ${widget.inputName}');
      // final koreanNameResponse =
      //     await _apiRepository.userService.generateKoreanName(widget.inputName);
      //
      // debugPrint(
      //     '한국 이름 생성 응답: ${koreanNameResponse.koreanName}, ${koreanNameResponse.englishPronunciation}');
      //
      // if (koreanNameResponse.koreanName.isEmpty) {
      //   throw Exception('한국 이름이 생성되지 않았습니다.');
      // }
      //
      // if (mounted) {
      //   // 로딩 완료 후 이름 확인 화면으로 이동
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => OnboardingNameConfirmScreen(
      //         inputName: widget.inputName,
      //         koreanName: koreanNameResponse.koreanName,
      //         englishPronunciation: koreanNameResponse.englishPronunciation,
      //       ),
      //     ),
      //   );
      // }

      // 임시: 서버 연결 없이 더미 데이터 사용
      await Future.delayed(const Duration(seconds: 2)); // 로딩 시간 시뮬레이션
      
      // 입력 이름에 따라 더미 한국 이름 생성
      final dummyKoreanName = _generateDummyKoreanName(widget.inputName);
      final dummyEnglishPronunciation = _generateDummyEnglishPronunciation(widget.inputName);

      if (mounted) {
        // 로딩 완료 후 이름 확인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingNameConfirmScreen(
              inputName: widget.inputName,
              koreanName: dummyKoreanName,
              englishPronunciation: dummyEnglishPronunciation,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('한국 이름 생성 에러: $e');
      if (mounted) {
        // 에러 발생 시에도 더미 데이터로 진행
        final dummyKoreanName = _generateDummyKoreanName(widget.inputName);
        final dummyEnglishPronunciation = _generateDummyEnglishPronunciation(widget.inputName);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingNameConfirmScreen(
              inputName: widget.inputName,
              koreanName: dummyKoreanName,
              englishPronunciation: dummyEnglishPronunciation,
            ),
          ),
        );
      }
    }
  }

  // 더미 한국 이름 생성 (입력 이름의 첫 글자를 기반으로)
  String _generateDummyKoreanName(String inputName) {
    if (inputName.isEmpty) return "김민수";
    
    // 간단한 매핑 (실제로는 서버에서 생성)
    final nameMap = {
      'a': '김', 'b': '이', 'c': '박', 'd': '최', 'e': '정',
      'f': '강', 'g': '조', 'h': '윤', 'i': '장', 'j': '임',
      'k': '한', 'l': '오', 'm': '서', 'n': '신', 'o': '권',
      'p': '황', 'q': '안', 'r': '송', 's': '류', 't': '전',
      'u': '홍', 'v': '고', 'w': '문', 'x': '양', 'y': '손', 'z': '배',
    };
    
    final firstChar = inputName.toLowerCase().substring(0, 1);
    final surname = nameMap[firstChar] ?? '김';
    final givenNames = ['민수', '지영', '현우', '서연', '준호', '수진', '동현', '예진'];
    final givenName = givenNames[inputName.length % givenNames.length];
    
    return '$surname$givenName';
  }

  // 더미 영어 발음 생성
  String _generateDummyEnglishPronunciation(String inputName) {
    if (inputName.isEmpty) return "Kim-Min-Su";
    return inputName.split('').map((c) => c.toUpperCase()).join('-');
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
