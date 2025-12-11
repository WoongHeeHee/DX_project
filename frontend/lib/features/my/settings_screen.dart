// lib/features/my/settings_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../providers/auth_provider.dart";
import "../../data/repositories/api_repository.dart";
import "../onboarding/onboarding_language_screen.dart" show LanguageOption;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _apiRepository = ApiRepository();
  bool _isLoading = false;
  bool _isGeneratingName = false;

  // 사용자 정보
  String? _koreanName;
  String? _englishPronunciation;
  String? _selectedLanguage;
  String? _birthYyyyMm;
  int _spicyLevel = 1;

  // 언어 옵션
  final List<LanguageOption> _languages = [
    LanguageOption(
      code: "ko",
      name: "Korean",
      greeting: "안녕하세요!\n한국어가 편하신가요?",
    ),
    LanguageOption(
      code: "en",
      name: "English",
      greeting: "Hello!\nDo you speak English?",
    ),
    LanguageOption(
      code: "zh",
      name: "Chinese",
      greeting: "你好！\n是中国人吗？",
    ),
    LanguageOption(
      code: "ja",
      name: "Japanese",
      greeting: "こんにちは！\n日本の方ですか？",
    ),
  ];

  late AnimationController _spicyAnimationController;
  late Animation<double> _spicyAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _spicyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _spicyAnimation = CurvedAnimation(
      parent: _spicyAnimationController,
      curve: Curves.easeOut,
    );
    _spicyAnimationController.forward();
  }

  @override
  void dispose() {
    _spicyAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      // korean_name에서 영어 발음 파싱
      String? englishPronunciation;
      if (user.koreanName != null) {
        final koreanNameValue = user.koreanName!;
        // "(한국이름, 영어발음)" 형식인지 확인
        if (koreanNameValue.contains(',') && koreanNameValue.startsWith('(') && koreanNameValue.endsWith(')')) {
          final parts = koreanNameValue.substring(1, koreanNameValue.length - 1).split(',');
          if (parts.length >= 2) {
            englishPronunciation = parts[1].trim();
          }
        }
      }
      
      setState(() {
        _koreanName = user.koreanName;
        _englishPronunciation = englishPronunciation;
        _selectedLanguage = user.locale.value;
        _birthYyyyMm = user.birthYyyyMm;
        _spicyLevel = user.spiceLevel;
      });
    }
  }

  Future<void> _regenerateKoreanName() async {
    if (_isGeneratingName) return;

    setState(() {
      _isGeneratingName = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final inputName = user?.displayName ?? "";

      final response =
          await _apiRepository.userService.generateKoreanName(inputName);

      setState(() {
        _koreanName = response.koreanName;
        _englishPronunciation = response.englishPronunciation;
        _isGeneratingName = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingName = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("이름 생성 실패: $e"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => _LanguageSelectionDialog(
        languages: _languages,
        selectedLanguage: _selectedLanguage ?? "ko",
        onLanguageSelected: (languageCode) {
          setState(() {
            _selectedLanguage = languageCode;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showYearMonthPicker() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    int? initialYear = currentYear;
    int? initialMonth = currentMonth;

    if (_birthYyyyMm != null) {
      final parts = _birthYyyyMm!.split("-");
      if (parts.length == 2) {
        initialYear = int.tryParse(parts[0]);
        initialMonth = int.tryParse(parts[1]);
      }
    }

    showDialog(
      context: context,
      builder: (context) => YearMonthPickerDialog(
        initialYear: initialYear ?? currentYear,
        initialMonth: initialMonth ?? currentMonth,
        maxYear: currentYear,
        maxMonth: currentMonth,
        onSelected: (year, month) {
          final monthStr = month.toString().padLeft(2, "0");
          setState(() {
            _birthYyyyMm = "$year-$monthStr";
          });
        },
      ),
    );
  }

  String _formatDate() {
    if (_birthYyyyMm != null) {
      return _birthYyyyMm!;
    }
    return "";
  }

  String _getLanguageName(String code) {
    final language = _languages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => _languages[0],
    );
    return language.name;
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // API 호출하여 설정 저장
      await _apiRepository.userService.updateProfileSettings(
        koreanName: _koreanName,
        locale: _selectedLanguage,
        birthYyyyMm: _birthYyyyMm,
        spiceLevel: _spicyLevel,
      );

      // AuthProvider 업데이트
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("설정이 저장되었습니다"),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("저장 실패: $e"),
            backgroundColor: AppColors.primary,
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("로그아웃"),
        content: Text("정말 로그아웃하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                context.go("/login");
              }
            },
            child: Text(
              "로그아웃",
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
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
            // 상단 헤더
            _buildHeader(responsive, textTheme),
            // 메인 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                child: ResponsivePadding(
                  mobileEdgeInsets: EdgeInsets.only(
                    left: responsive.responsivePadding(mobilePadding: 20),
                    right: responsive.responsivePadding(mobilePadding: 20),
                    top: responsive.responsivePadding(mobilePadding: 20),
                    bottom: responsive.responsivePadding(mobilePadding: 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 프로필 섹션
                      _buildProfileSection(responsive, textTheme),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 40),
                      ),
                      // 설정 옵션
                      _buildLanguageOption(responsive, textTheme),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 20),
                      ),
                      _buildAgeOption(responsive, textTheme),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 20),
                      ),
                      _buildSpicyLevelOption(responsive, textTheme),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 40),
                      ),
                      // 하단 버튼
                      _buildSaveButton(responsive, textTheme),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 12),
                      ),
                      _buildLogoutButton(responsive, textTheme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
        vertical: responsive.responsivePadding(mobilePadding: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.chevron_left,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.mainText,
            ),
          ),
          Text(
            "프로필 수정",
            style: textTheme.titleLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 20),
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(
            width: responsive.responsiveIconSize(mobileSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 프로필 사진
        Column(
          children: [
            Container(
              width: responsive.responsiveFontSize(mobileSize: 100),
              height: responsive.responsiveFontSize(mobileSize: 100),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.3),
              ),
              child: Icon(
                Icons.person,
                size: responsive.responsiveFontSize(mobileSize: 50),
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 8),
            ),
            TextButton(
              onPressed: () {
                // TODO: 프로필 사진 변경
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "사진 변경",
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainText,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          width: responsive.responsivePadding(mobilePadding: 20),
        ),
        // 이름 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 한국어 이름
              Text(
                _koreanName ?? "김가희",
                style: textTheme.titleLarge?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainText,
                ),
              ),
              SizedBox(
                height: responsive.responsivePadding(mobilePadding: 4),
              ),
              // 영문 발음
              Text(
                _englishPronunciation ?? "Kim Ga-hee",
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 14),
                  fontWeight: FontWeight.w400,
                  color: AppColors.inactiveText,
                ),
              ),
              SizedBox(
                height: responsive.responsivePadding(mobilePadding: 12),
              ),
              // 한국 이름 다시 만들기 버튼
              Row(
                children: [
                  Text(
                    "한국 이름 다시 만들기",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainText,
                    ),
                  ),
                  SizedBox(
                    width: responsive.responsivePadding(mobilePadding: 8),
                  ),
                  IconButton(
                    onPressed: _isGeneratingName ? null : _regenerateKoreanName,
                    icon: _isGeneratingName
                        ? SizedBox(
                            width:
                                responsive.responsiveIconSize(mobileSize: 16),
                            height:
                                responsive.responsiveIconSize(mobileSize: 16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.refresh,
                            size: responsive.responsiveIconSize(mobileSize: 16),
                            color: AppColors.primary,
                          ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "언어",
          style: textTheme.bodyMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 16),
            fontWeight: FontWeight.w600,
            color: AppColors.mainText,
          ),
        ),
        SizedBox(
          height: responsive.responsivePadding(mobilePadding: 8),
        ),
        GestureDetector(
          onTap: _showLanguageDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.responsivePadding(mobilePadding: 16),
              vertical: responsive.responsivePadding(mobilePadding: 12),
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: const Color(0xFFF7F7F8),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getLanguageName(_selectedLanguage ?? "ko"),
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 16),
                    fontWeight: FontWeight.w500,
                    color: AppColors.mainText,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: responsive.responsiveIconSize(mobileSize: 16),
                  color: AppColors.mainText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeOption(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final hasSelection = _birthYyyyMm != null && _birthYyyyMm!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "나이",
          style: textTheme.bodyMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 16),
            fontWeight: FontWeight.w600,
            color: AppColors.mainText,
          ),
        ),
        SizedBox(
          height: responsive.responsivePadding(mobilePadding: 8),
        ),
        GestureDetector(
          onTap: _showYearMonthPicker,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.responsivePadding(mobilePadding: 16),
              vertical: responsive.responsivePadding(mobilePadding: 12),
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: const Color(0xFFF7F7F8),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasSelection ? _formatDate() : "출생연도·월 선택하기",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 16),
                    fontWeight:
                        hasSelection ? FontWeight.w600 : FontWeight.w500,
                    color: hasSelection
                        ? AppColors.mainText
                        : AppColors.inactiveText,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: responsive.responsiveIconSize(mobileSize: 16),
                  color: AppColors.mainText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpicyLevelOption(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "맵기 Lv",
          style: textTheme.bodyMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 16),
            fontWeight: FontWeight.w600,
            color: AppColors.mainText,
          ),
        ),
        SizedBox(
          height: responsive.responsivePadding(mobilePadding: 20),
        ),
        _buildSpicyLevelSlider(responsive, textTheme),
      ],
    );
  }

  Widget _buildSpicyLevelSlider(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final circleRadius = 9.0;
    final circleDiameter = circleRadius * 2;
    final gaugeHeight = 4.0;
    final endMargin = 16.0;
    final int totalSteps = 5;

    final Map<int, String> levelLabels = {
      1: "아직\n어려워요",
      3: "김치",
      5: "불닭소스",
    };

    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final padding = responsive.responsivePadding(mobilePadding: 20) * 2;
        final sliderWidth = screenWidth - padding;

        final availableWidth = sliderWidth - (endMargin * 2) - circleDiameter;
        final stepDistance = availableWidth / (totalSteps - 1);

        final circlePositions = List.generate(totalSteps, (index) {
          return endMargin + circleRadius + (stepDistance * index);
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: sliderWidth,
              height: circleDiameter + 8,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final localPosition = details.localPosition.dx;
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
                    _spicyAnimationController.forward(from: 0.0);
                  }
                },
                onTapDown: (details) {
                  final localPosition = details.localPosition.dx;
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
                    _spicyAnimationController.forward(from: 0.0);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
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
                    AnimatedBuilder(
                      animation: _spicyAnimation,
                      builder: (context, child) {
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
                    ...List.generate(totalSteps, (index) {
                      final step = index + 1;
                      final isActive = _spicyLevel >= step;
                      final position = circlePositions[index];

                      return Positioned(
                        left: position - circleRadius,
                        top: 0,
                        child: AnimatedBuilder(
                          animation: _spicyAnimation,
                          builder: (context, child) {
                            final scale = (step == _spicyLevel &&
                                    _spicyAnimation.value > 0)
                                ? 1.0 + (_spicyAnimation.value * 0.1)
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
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (levelLabels.containsKey(1))
                  Text(
                    levelLabels[1]!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.inactiveText,
                    ),
                  )
                else
                  SizedBox.shrink(),
                if (levelLabels.containsKey(3))
                  Text(
                    levelLabels[3]!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.inactiveText,
                    ),
                  )
                else
                  SizedBox.shrink(),
                if (levelLabels.containsKey(5))
                  Text(
                    levelLabels[5]!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 12),
                      fontWeight: FontWeight.w500,
                      color: AppColors.inactiveText,
                    ),
                  )
                else
                  SizedBox.shrink(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSaveButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              )
            : Text(
                "저장하기",
                style: textTheme.titleMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLogoutButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _showLogoutConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.softGreyBackground,
          foregroundColor: AppColors.mainText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          "로그아웃",
          style: textTheme.titleMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 16),
            fontWeight: FontWeight.w600,
            color: AppColors.mainText,
          ),
        ),
      ),
    );
  }
}

// 언어 선택 다이얼로그
class _LanguageSelectionDialog extends StatelessWidget {
  final List<LanguageOption> languages;
  final String selectedLanguage;
  final void Function(String) onLanguageSelected;

  const _LanguageSelectionDialog({
    required this.languages,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

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
              "언어 선택",
              style: textTheme.titleLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 20),
                fontWeight: FontWeight.w600,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            ...languages.map((language) {
              final isSelected = selectedLanguage == language.code;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: responsive.responsivePadding(mobilePadding: 10),
                ),
                child: GestureDetector(
                  onTap: () => onLanguageSelected(language.code),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          responsive.responsivePadding(mobilePadding: 12),
                      vertical: responsive.responsivePadding(mobilePadding: 14),
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.white,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: const Color(0xFFF7F7F8),
                              width: 1,
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.greeting,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize:
                                responsive.responsiveFontSize(mobileSize: 16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainText,
                          ),
                        ),
                        SizedBox(
                          height:
                              responsive.responsivePadding(mobilePadding: 4),
                        ),
                        Text(
                          language.name,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize:
                                responsive.responsiveFontSize(mobileSize: 13),
                            fontWeight: FontWeight.w400,
                            color: AppColors.inactiveText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// 년도와 월만 선택하는 커스텀 다이얼로그 (온보딩에서 재사용)
class YearMonthPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final int maxYear;
  final int maxMonth;
  final void Function(int year, int month) onSelected;

  const YearMonthPickerDialog({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    required this.maxYear,
    required this.maxMonth,
    required this.onSelected,
  });

  @override
  State<YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<YearMonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;

    final years = List.generate(
      widget.maxYear - 1925 + 1,
      (index) => 1925 + index,
    ).reversed.toList();

    final yearIndex = years.indexOf(_selectedYear);
    _yearController = FixedExtentScrollController(
        initialItem: yearIndex >= 0 ? yearIndex : 0);

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

    final years = List.generate(
      widget.maxYear - 1925 + 1,
      (index) => 1925 + index,
    ).reversed.toList();

    final months = List.generate(12, (index) => index + 1);

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
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "년도",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize:
                              responsive.responsiveFontSize(mobileSize: 14),
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
                                    fontSize: responsive.responsiveFontSize(
                                        mobileSize: 18),
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
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "월",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize:
                              responsive.responsiveFontSize(mobileSize: 14),
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
                              if (index < 0 ||
                                  index >= availableMonths.length) {
                                return null;
                              }
                              final month = availableMonths[index];
                              final isSelected = month == _selectedMonth;
                              return Center(
                                child: Text(
                                  "$month",
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontSize: responsive.responsiveFontSize(
                                        mobileSize: 18),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "취소",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 16),
                      fontWeight: FontWeight.w500,
                      color: AppColors.inactiveText,
                    ),
                  ),
                ),
                SizedBox(
                  width: responsive.responsivePadding(mobilePadding: 12),
                ),
                ElevatedButton(
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
                  ),
                  child: Text(
                    "확인",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
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

