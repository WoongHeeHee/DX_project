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
  int? _selectedYear;
  int? _selectedMonth;
  bool _isFocused = false;

  String _formatDate() {
    if (_selectedYear != null && _selectedMonth != null) {
      final month = _selectedMonth!.toString().padLeft(2, '0');
      return "$_selectedYear-$month";
    }
    return "";
  }

  void _showYearMonthPicker() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    showDialog(
      context: context,
      builder: (context) => _YearMonthPickerDialog(
        initialYear: _selectedYear ?? currentYear,
        initialMonth: _selectedMonth ?? currentMonth,
        maxYear: currentYear,
        maxMonth: currentMonth,
        onSelected: (year, month) {
          setState(() {
            _selectedYear = year;
            _selectedMonth = month;
            _isFocused = false;
          });
        },
      ),
    );
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
            // STEP 4 · Age
            Text(
              "STEP 4 · Age",
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
              "$userName님,\n몇 년생이신가요?",
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
    final hasSelection = _selectedYear != null && _selectedMonth != null;
    final textSize = responsive.responsiveFontSize(mobileSize: 16);

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isFocused = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isFocused = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isFocused = false;
        });
      },
      onTap: () {
        setState(() {
          _isFocused = true;
        });
        _showYearMonthPicker();
      },
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          // 국가 선택 박스처럼 높이를 1.5배로 설정
          minHeight: ((textSize * 1.25) + 
              (responsive.responsivePadding(mobilePadding: 12) * 2)) * 1.5,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 16),
          vertical: responsive.responsivePadding(mobilePadding: 12),
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
              child: Text(
                hasSelection
                    ? _formatDate()
                    : "출생연도·월 선택하기",
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: textSize,
                  fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                  color: hasSelection
                      ? AppColors.mainText
                      : AppColors.inactiveText,
                  letterSpacing: hasSelection ? 0 : 0.5,
                ),
              ),
            ),
            SizedBox(width: responsive.responsivePadding(mobilePadding: 8)),
            Icon(
              Icons.keyboard_arrow_down,
              size: responsive.responsiveIconSize(mobileSize: 16),
              color: AppColors.mainText,
            ),
          ],
        ),
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
          onPressed: () {
            if (_selectedYear != null && _selectedMonth != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OnboardingSpicyLevelScreen(
                    userName: widget.userName,
                    countryName: widget.countryName,
                    countryId: widget.countryId,
                    birthYyyyMm: _formatDate(),
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

// 년도와 월만 선택하는 커스텀 다이얼로그
class _YearMonthPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final int maxYear;
  final int maxMonth;
  final void Function(int year, int month) onSelected;

  const _YearMonthPickerDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.maxYear,
    required this.maxMonth,
    required this.onSelected,
  });

  @override
  State<_YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    
    // 년도 리스트 생성 (1925년부터 현재 년도까지)
    final years = List.generate(
      widget.maxYear - 1925 + 1,
      (index) => 1925 + index,
    ).reversed.toList();
    
    final yearIndex = years.indexOf(_selectedYear);
    _yearController = FixedExtentScrollController(initialItem: yearIndex >= 0 ? yearIndex : 0);
    
    final monthIndex = _selectedMonth - 1;
    _monthController = FixedExtentScrollController(initialItem: monthIndex);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    
    // 년도 리스트 생성 (1925년부터 현재 년도까지)
    final years = List.generate(
      widget.maxYear - 1925 + 1,
      (index) => 1925 + index,
    ).reversed.toList();
    
    // 월 리스트 생성
    final months = List.generate(12, (index) => index + 1);
    
    // 현재 선택된 년도가 최대 년도인 경우, 최대 월까지만 표시
    final availableMonths = _selectedYear == widget.maxYear
        ? months.where((m) => m <= widget.maxMonth).toList()
        : months;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(
          responsive.responsivePadding(mobilePadding: 24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "출생 연도·월 선택",
              style: textTheme.titleLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 20),
                fontWeight: FontWeight.w600,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 24),
            ),
            Row(
              children: [
                // 년도 선택
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "년도",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: responsive.responsiveFontSize(mobileSize: 14),
                          fontWeight: FontWeight.w500,
                          color: AppColors.inactiveText,
                        ),
                      ),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 8),
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(
                            color: const Color(0xFFF7F7F8),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListWheelScrollView.useDelegate(
                          controller: _yearController,
                          itemExtent: 50,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedYear = years[index];
                              // 년도가 변경되면 월도 조정
                              if (_selectedYear == widget.maxYear &&
                                  _selectedMonth > widget.maxMonth) {
                                _selectedMonth = widget.maxMonth;
                                _monthController.animateToItem(
                                  _selectedMonth - 1,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= years.length) {
                                return null;
                              }
                              final year = years[index];
                              final isSelected = year == _selectedYear;
                              return Center(
                                child: Text(
                                  "$year",
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontSize: responsive.responsiveFontSize(mobileSize: 18),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.mainText,
                                  ),
                                ),
                              );
                            },
                            childCount: years.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: responsive.responsivePadding(mobilePadding: 16),
                ),
                // 월 선택
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "월",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: responsive.responsiveFontSize(mobileSize: 14),
                          fontWeight: FontWeight.w500,
                          color: AppColors.inactiveText,
                        ),
                      ),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 8),
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(
                            color: const Color(0xFFF7F7F8),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListWheelScrollView.useDelegate(
                          controller: _monthController,
                          itemExtent: 50,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            if (index >= 0 && index < availableMonths.length) {
                              setState(() {
                                _selectedMonth = availableMonths[index];
                              });
                            }
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index >= availableMonths.length) {
                                return null;
                              }
                              final month = availableMonths[index];
                              final isSelected = month == _selectedMonth;
                              return Center(
                                child: Text(
                                  "$month월",
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontSize: responsive.responsiveFontSize(mobileSize: 18),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.mainText,
                                  ),
                                ),
                              );
                            },
                            childCount: availableMonths.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 24),
            ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: responsive.responsivePadding(mobilePadding: 14) * 2 * 1.5,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainText,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.responsivePadding(mobilePadding: 14),
                        ),
                      ),
                      child: Text(
                        "취소",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: responsive.responsivePadding(mobilePadding: 12),
                ),
                Expanded(
                  child: SizedBox(
                    height: responsive.responsivePadding(mobilePadding: 14) * 2 * 1.5,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSelected(_selectedYear, _selectedMonth);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.responsivePadding(mobilePadding: 14),
                        ),
                      ),
                      child: Text(
                        "확인",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

