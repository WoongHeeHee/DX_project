// lib/features/onboarding/onboarding_country_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/custom_dropdown.dart";
import "../home/models/filter_model.dart";

class OnboardingCountryScreen extends StatefulWidget {
  final String? userName; // 사용자 이름

  const OnboardingCountryScreen({
    super.key,
    this.userName,
  });

  @override
  State<OnboardingCountryScreen> createState() =>
      _OnboardingCountryScreenState();
}

class _OnboardingCountryScreenState extends State<OnboardingCountryScreen> {
  bool showCountryDropdown = false;
  CountryFilter? selectedCountry;

  // 국가 리스트 (explore_screen과 동일)
  final List<CountryFilter> countries = [
    CountryFilter(
      id: "country_jp",
      name: "일본",
      flagImageUrl: "assets/images/JP.gif",
    ),
    CountryFilter(
      id: "country_us",
      name: "미국",
      flagImageUrl: "assets/images/US.gif",
    ),
    CountryFilter(
      id: "country_cn",
      name: "중국",
      flagImageUrl: "assets/images/CN.gif",
    ),
    CountryFilter(
      id: "country_kr",
      name: "한국",
      flagImageUrl: null,
    ),
    CountryFilter(
      id: "country_th",
      name: "태국",
      flagImageUrl: "assets/images/TH.gif",
    ),
    CountryFilter(
      id: "country_vn",
      name: "베트남",
      flagImageUrl: "assets/images/VN.gif",
    ),
    CountryFilter(
      id: "country_sg",
      name: "싱가포르",
      flagImageUrl: "assets/images/SG.gif",
    ),
    CountryFilter(
      id: "country_my",
      name: "말레이시아",
      flagImageUrl: "assets/images/MY.gif",
    ),
    CountryFilter(
      id: "country_id",
      name: "인도네시아",
      flagImageUrl: "assets/images/ID.gif",
    ),
    CountryFilter(
      id: "country_ph",
      name: "필리핀",
      flagImageUrl: "assets/images/PH.gif",
    ),
    CountryFilter(
      id: "country_in",
      name: "인도",
      flagImageUrl: "assets/images/IN.gif",
    ),
    CountryFilter(
      id: "country_tw",
      name: "대만",
      flagImageUrl: "assets/images/TW.gif",
    ),
    CountryFilter(
      id: "country_hk",
      name: "홍콩",
      flagImageUrl: "assets/images/HK.gif",
    ),
    CountryFilter(
      id: "country_au",
      name: "호주",
      flagImageUrl: "assets/images/AU.gif",
    ),
    CountryFilter(
      id: "country_ca",
      name: "캐나다",
      flagImageUrl: "assets/images/CA.gif",
    ),
    CountryFilter(
      id: "country_gb",
      name: "영국",
      flagImageUrl: "assets/images/GB.gif",
    ),
    CountryFilter(
      id: "country_fr",
      name: "프랑스",
      flagImageUrl: "assets/images/FR.gif",
    ),
    CountryFilter(
      id: "country_de",
      name: "독일",
      flagImageUrl: "assets/images/DE.gif",
    ),
    CountryFilter(
      id: "country_ru",
      name: "러시아",
      flagImageUrl: "assets/images/RU.gif",
    ),
    CountryFilter(
      id: "country_mx",
      name: "멕시코",
      flagImageUrl: "assets/images/MX.gif",
    ),
    CountryFilter(
      id: "country_mn",
      name: "몽골",
      flagImageUrl: "assets/images/MN.gif",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final userName = widget.userName ?? "김가희"; // 기본값

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // 드롭다운 외부 클릭 시 닫기
            if (showCountryDropdown) {
              setState(() {
                showCountryDropdown = false;
              });
            }
          },
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
      ),
    );
  }

  Widget _buildProgressIndicator(ResponsiveHelper responsive) {
    const int totalSteps = 7;
    const int currentStep = 3; // STEP 3
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
            // STEP 3 · Country
            Text(
              "STEP 3 · Country",
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
              "$userName님,\n어느 나라에서 오셨나요?",
              style: textTheme.headlineLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 26),
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            // 국가 선택 드롭다운
            _buildCountryDropdown(responsive, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryDropdown(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return CustomDropdown<CountryFilter>(
      selectedValue: selectedCountry,
      items: countries,
      getLabel: (country) => country.name,
      getImageUrl: (country) => country.flagImageUrl,
      onItemSelected: (country) {
        setState(() {
          selectedCountry = country;
          showCountryDropdown = false;
        });
      },
      isOpen: showCountryDropdown,
      onToggle: () {
        setState(() {
          showCountryDropdown = !showCountryDropdown;
        });
      },
      width: null, // null로 설정하면 전체 너비 사용
      maxHeight: 300,
      placeholder: "국가 선택하기",
      showCheckIcon: true,
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
            if (selectedCountry != null) {
              context.push(
                '/onboarding/age',
                extra: {
                  'userName': widget.userName,
                  'countryName': selectedCountry!.name,
                  'countryId': selectedCountry!.id,
                },
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
