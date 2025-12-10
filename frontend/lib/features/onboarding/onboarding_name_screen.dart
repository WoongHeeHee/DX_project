// lib/features/onboarding/onboarding_name_screen.dart

import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "onboarding_loading_screen.dart";

class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {});
    });
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

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
    const int currentStep = 2;
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
            // STEP 2 · Name
            Text(
              "STEP 2 · Name",
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
              "당신의 이름은 무엇인가요?",
              style: textTheme.headlineLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 26),
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 30),
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
    final hasText = _nameController.text.isNotEmpty;
    final textSize = responsive.responsiveFontSize(mobileSize: 16);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: responsive.responsivePadding(mobilePadding: 16),
        right: responsive.responsivePadding(mobilePadding: 16),
        top: responsive.responsivePadding(mobilePadding: 12),
        bottom: responsive.responsivePadding(mobilePadding: 12),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: _isFocused
              ? AppColors.mainText.withOpacity(0.5)
              : const Color(0xFFF7F7F8),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              cursorColor: AppColors.primary,
              onSubmitted: (_) {
                _dismissKeyboard();
              },
              style: textTheme.bodyMedium?.copyWith(
                fontSize: textSize,
                fontWeight: hasText ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.mainText,
              ),
              decoration: InputDecoration(
                hintText: "이름 입력하기",
                hintStyle: textTheme.bodyMedium?.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inactiveText,
                  letterSpacing: 0.5,
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
          ),
          if (hasText)
            Padding(
              padding: EdgeInsets.only(
                left: responsive.responsivePadding(mobilePadding: 8),
              ),
              child: GestureDetector(
                onTap: () {
                  _nameController.clear();
                },
                child: Container(
                  width: textSize,
                  height: textSize,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close,
                    size: textSize,
                    color: AppColors.mainText,
                  ),
                ),
              ),
            ),
        ],
      ),
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
            if (_nameController.text.trim().isNotEmpty) {
              // 바로 로딩 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OnboardingLoadingScreen(
                    inputName: _nameController.text.trim(),
                  ),
                ),
              );
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
            "입력 완료",
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

