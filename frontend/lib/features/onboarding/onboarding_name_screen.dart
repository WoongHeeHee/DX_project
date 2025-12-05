// lib/features/onboarding/onboarding_name_screen.dart

import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../data/repositories/api_repository.dart";
import "onboarding_loading_screen.dart";
import "onboarding_name_confirm_screen.dart";

class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  final _apiRepository = ApiRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

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
              child: _buildContent(responsive, textTheme),
            ),
            // 하단 버튼 (키보드가 올라오면 숨김 버튼으로 변경)
            isKeyboardVisible
                ? _buildKeyboardDismissButton(responsive, textTheme)
                : _buildBottomButton(responsive, textTheme),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ResponsiveHelper responsive) {
    const int totalSteps = 7;
    const int currentStep = 2;
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
            // STEP 2 · Name
            Text(
              "STEP 2 · Name",
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
              "당신의 이름은 무엇인가요?",
              style: textTheme.headlineLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 26),
                fontWeight: FontWeight.w400,
                height: 1,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            // 이름 입력 필드
            _buildNameInputField(responsive, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInputField(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 12),
        vertical: responsive.responsivePadding(mobilePadding: 14),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _nameController,
        focusNode: _focusNode,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          _dismissKeyboard();
        },
        style: textTheme.bodyMedium?.copyWith(
          fontSize: responsive.responsiveFontSize(mobileSize: 14),
          fontWeight: FontWeight.w500,
          color: AppColors.mainText,
        ),
        decoration: InputDecoration(
          hintText: "이름 입력하기",
          hintStyle: textTheme.bodyMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 14),
            fontWeight: FontWeight.w500,
            color: AppColors.inactiveText,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildKeyboardDismissButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: GestureDetector(
        onTap: _dismissKeyboard,
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
            "키보드 숨기기",
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
            if (_nameController.text.trim().isNotEmpty) {
              setState(() {
                _isLoading = true;
              });

              try {
                // 한국 이름 생성 API 호출
                debugPrint('한국 이름 생성 요청: ${_nameController.text.trim()}');
                final koreanNameResponse = await _apiRepository.userService
                    .generateKoreanName(_nameController.text.trim());
                
                debugPrint('한국 이름 생성 응답: ${koreanNameResponse.koreanName}, ${koreanNameResponse.englishPronunciation}');

                if (koreanNameResponse.koreanName.isEmpty) {
                  throw Exception('한국 이름이 생성되지 않았습니다.');
                }

                if (mounted) {
                  // 로딩 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingLoadingScreen(
                        onComplete: () {
                          // 로딩 완료 후 이름 확인 화면으로 이동
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OnboardingNameConfirmScreen(
                                inputName: _nameController.text.trim(),
                                koreanName: koreanNameResponse.koreanName,
                                englishPronunciation:
                                    koreanNameResponse.englishPronunciation,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('한국 이름 생성 에러: $e');
                if (mounted) {
                  // 에러 화면 대신 스낵바로 표시하고 재시도 가능하도록
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('한국 이름 생성에 실패했습니다: ${e.toString()}'),
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: '다시 시도',
                        onPressed: () {
                          // 재시도 로직은 사용자가 버튼을 다시 누르면 실행됨
                        },
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
            }
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
            "입력 완료",
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

