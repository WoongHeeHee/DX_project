// lib/features/onboarding/onboarding_age_screen.dart

import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "onboarding_spicy_level_screen.dart";

class OnboardingAgeScreen extends StatefulWidget {
  final String? userName; // 사용자 이름
  final String? countryName; // 국가 이름
  final String? countryId; // 국가 ID

  const OnboardingAgeScreen({
    super.key,
    this.userName,
    this.countryName,
    this.countryId,
  });

  @override
  State<OnboardingAgeScreen> createState() => _OnboardingAgeScreenState();
}

class _OnboardingAgeScreenState extends State<OnboardingAgeScreen> {
  DateTime? _selectedDate;

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    return "$year-$month";
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
    const int totalSteps = 7;
    const int currentStep = 4; // STEP 4
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
            // STEP 4 · Age
            Text(
              "STEP 4 · Age",
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
              "$userName님,\n몇 년생이신가요?",
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
            // 출생 연도 선택
            _buildDatePickerField(responsive, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Padding(
          padding: EdgeInsets.only(
            bottom: responsive.responsivePadding(mobilePadding: 2),
          ),
          child: Text(
            "출생 연도",
            style: textTheme.bodyMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 13),
              fontWeight: FontWeight.w500,
              color: AppColors.inactiveText,
            ),
          ),
        ),
        SizedBox(
          height: responsive.responsivePadding(mobilePadding: 12),
        ),
        // 날짜 선택 필드
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final firstDate = DateTime(1925, 1, 1);
            final lastDate = DateTime(now.year, now.month, now.day);

            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? lastDate,
              firstDate: firstDate,
              lastDate: lastDate,
              initialDatePickerMode: DatePickerMode.year,
              helpText: "출생 연도 선택",
              locale: const Locale('ko', 'KR'),
            );

            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              responsive.responsivePadding(mobilePadding: 12),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _selectedDate != null
                      ? _formatDate(_selectedDate!)
                      : "yyyy-mm",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 14),
                    fontWeight: FontWeight.w500,
                    color: _selectedDate != null
                        ? AppColors.mainText
                        : AppColors.inactiveText,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: responsive.responsiveIconSize(mobileSize: 16),
                  color: AppColors.inactiveText,
                ),
              ],
            ),
          ),
        ),
      ],
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
            if (_selectedDate != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OnboardingSpicyLevelScreen(
                    userName: widget.userName,
                    countryName: widget.countryName,
                    countryId: widget.countryId,
                    birthYyyyMm: _formatDate(_selectedDate!),
                  ),
                ),
              );
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

