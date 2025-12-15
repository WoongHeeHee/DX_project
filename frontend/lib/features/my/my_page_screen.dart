// lib/features/my/my_page_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../widgets/bottom_navigation_bar.dart";
import "../../providers/auth_provider.dart";
import "../../data/repositories/api_repository.dart";
import "dart:async";
import "settings_screen.dart";
import "saved_stores_screen.dart";
import "saved_foods_screen.dart";
import "market_history_screen.dart";
import "market_review_write_screen.dart";
import "demo_diary_write_screen.dart";
import "gift_popup_dialog.dart";
import "coupon_detail_screen.dart";

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _apiRepository = ApiRepository();
  bool _showFloatingButton = false; // 리뷰 작성 이벤트 발생 시 true
  bool _showToast = false; // 토스트 메시지 표시 여부
  Timer? _toastTimer;
  bool _hasRecentVisit = false; // 최근 방문 이력 (7일 이내)
  bool _hasMarketExperience = false; // 시장 방문 경험 여부
  String? _recentMarketName; // 최근 방문한 시장 이름
  String? _recentMarketId; // 최근 방문한 시장 ID (향후 사용 예정)
  bool _isLoadingVisitData = true;

  @override
  void initState() {
    super.initState();
    // 리뷰 작성 후 돌아왔는지 확인 (임시로 테스트용)
    // TODO: 실제로는 리뷰 저장 성공 시 플래그를 설정하거나 Navigator 결과로 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReviewCompletion();
      _loadVisitData();
    });
  }

  Future<void> _loadVisitData() async {
    try {
      final visitData = await _apiRepository.userService.getMarketVisits();
      setState(() {
        _hasRecentVisit = visitData.hasRecentVisit;
        _recentMarketName = visitData.marketName;
        _recentMarketId = visitData.marketId;
        _hasMarketExperience = !_hasRecentVisit; // 최근 방문이 없으면 경험이 없는 것으로 간주
        _isLoadingVisitData = false;
      });
    } catch (e) {
      debugPrint("방문 기록 조회 실패: $e");
      setState(() {
        _hasRecentVisit = false;
        _hasMarketExperience = false;
        _isLoadingVisitData = false;
      });
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _checkReviewCompletion() {
    // TODO: 리뷰 작성 완료 여부를 확인하는 로직
    // 예: SharedPreferences나 Provider를 통해 확인
    // 임시로 테스트를 위해 주석 처리
    // if (리뷰 작성 완료) {
    //   _showGiftPopup();
    // }
  }

  void _showGiftPopup() {
    GiftPopupDialog.show(
      context,
      onShowFloatingButton: () {
        setState(() {
          _showFloatingButton = true;
          _showToast = true;
        });
        // 5초 후 토스트 사라짐
        _toastTimer?.cancel();
        _toastTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showToast = false;
            });
          }
        });
      },
    );
  }

  void _onFloatingButtonTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CouponDetailScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final koreanName = user?.koreanName ?? "김가희";
    // korean_name이 "(한국이름, 영어발음)" 형식으로 저장될 수 있으므로 파싱
    String englishPronunciation = "Kim Ga-hee";
    if (user?.koreanName != null) {
      final koreanNameValue = user!.koreanName!;
      // "(한국이름, 영어발음)" 형식인지 확인
      if (koreanNameValue.contains(',') && koreanNameValue.startsWith('(') && koreanNameValue.endsWith(')')) {
        final parts = koreanNameValue.substring(1, koreanNameValue.length - 1).split(',');
        if (parts.length >= 2) {
          englishPronunciation = parts[1].trim();
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 설정 버튼
                _buildHeader(context, responsive, textTheme),
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
                        children: [
                          // 프로필 섹션
                          _buildProfileSection(
                            responsive,
                            textTheme,
                            koreanName,
                            englishPronunciation,
                          ),
                          SizedBox(
                            height:
                                responsive.responsivePadding(mobilePadding: 40),
                          ),
                          // 조건부 배너들 (위아래로 나열)
                          // 방문 기록 작성 가능 배너 (시장을 다녀온 이력이 있으면)
                          if (!_isLoadingVisitData && _hasRecentVisit)
                            _buildReviewWriteBanner(
                                responsive, textTheme, context),
                          if (!_isLoadingVisitData && _hasRecentVisit)
                            SizedBox(
                              height: responsive.responsivePadding(
                                  mobilePadding: 20),
                            ),
                          // 기록할 경험이 없어요 배너 (시장 방문 경험 없을 때)
                          if (!_isLoadingVisitData && !_hasMarketExperience)
                            _buildNoExperienceBanner(
                                responsive, textTheme, context),
                          if (!_isLoadingVisitData && !_hasMarketExperience)
                            SizedBox(
                              height: responsive.responsivePadding(
                                  mobilePadding: 20),
                            ),
                          // 버튼 섹션
                          _buildButtonSection(responsive, textTheme, context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 플로팅 버튼 (좌측 하단)
            if (_showFloatingButton)
              Positioned(
                left: responsive.responsivePadding(mobilePadding: 20),
                bottom: responsive.responsivePadding(mobilePadding: 80), // 하단 네비게이션 바 위 (더 하단으로 이동)
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 플로팅 버튼
                    GestureDetector(
                      onTap: _onFloatingButtonTap,
                      child: Container(
                        width: responsive.responsiveIconSize(mobileSize: 56),
                        height: responsive.responsiveIconSize(mobileSize: 56),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          color: AppColors.white,
                          size: responsive.responsiveIconSize(mobileSize: 28),
                        ),
                      ),
                    ),
                    // 토스트 메시지 (플로팅 버튼 우측, 가운데 정렬)
                    if (_showToast)
                      Padding(
                        padding: EdgeInsets.only(
                          left: responsive.responsivePadding(mobilePadding: 12),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                responsive.responsivePadding(mobilePadding: 12),
                            vertical:
                                responsive.responsivePadding(mobilePadding: 8),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mainText,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "← LG전자 리프레시룸 체험권이 기다리고 있을게요!",
                            style: textTheme.bodySmall?.copyWith(
                              fontSize:
                                  responsive.responsiveFontSize(mobileSize: 12),
                              fontWeight: FontWeight.w500,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: responsive.responsivePadding(mobilePadding: 20),
        right: responsive.responsivePadding(mobilePadding: 20),
        top: responsive.responsivePadding(mobilePadding: 16),
        bottom: responsive.responsivePadding(mobilePadding: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.settings,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.mainText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    String koreanName,
    String englishPronunciation,
  ) {
    return GestureDetector(
      onDoubleTap: () {
        // 더블탭 시 임의 다이어리 작성 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DemoDiaryWriteScreen(),
          ),
        );
      },
      child: Column(
        children: [
          // 프로필 사진
          Container(
            width: responsive.responsiveFontSize(mobileSize: 120),
            height: responsive.responsiveFontSize(mobileSize: 120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.3),
            ),
            child: Icon(
              Icons.person,
              size: responsive.responsiveFontSize(mobileSize: 60),
              color: AppColors.primary,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 20),
          ),
          // 한국어 이름
          Text(
            koreanName,
            style: textTheme.headlineLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 24),
              fontWeight: FontWeight.w700,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 8),
          ),
          // 영문 발음
          Text(
            englishPronunciation,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 16),
              fontWeight: FontWeight.w400,
              color: AppColors.inactiveText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewWriteBanner(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsive.responsivePadding(mobilePadding: 24),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // "방문 기록을 작성할 수 있어요!"
          Text(
            "방문 기록을 작성할 수 있어요!",
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 20),
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 12),
          ),
          // "경험을 남겨보세요"
          Text(
            "경험을 남겨보세요",
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 16),
              fontWeight: FontWeight.w400,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 20),
          ),
          // "작성하기" 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_recentMarketName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("시장 정보를 찾을 수 없습니다"),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  return;
                }
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarketReviewWriteScreen(
                      marketName: _recentMarketName!,
                    ),
                  ),
                );
                // 리뷰 작성 완료 시 팝업 표시 및 방문 데이터 새로고침
                if (result == true && mounted) {
                  _showGiftPopup();
                  _loadVisitData(); // 방문 데이터 새로고침
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  vertical:
                      responsive.responsivePadding(mobilePadding: 16) * 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Text(
                "작성하기",
                style: textTheme.titleMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExperienceBanner(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsive.responsivePadding(mobilePadding: 24),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // "기록할 경험이 없어요!"
          Text(
            "기록할 경험이 없어요",
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 20),
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 12),
          ),
          // "시장을 둘러보고 경험을 남겨보세요"
          Text(
            "시장을 둘러보고 경험을 남겨보세요",
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 16),
              fontWeight: FontWeight.w400,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 20),
          ),
          // "시장 둘러보기" 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: 시장 둘러보기 화면으로 이동
                context.go("/explore");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  vertical:
                      responsive.responsivePadding(mobilePadding: 16) * 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Text(
                "시장 둘러보기",
                style: textTheme.titleMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    BuildContext context,
  ) {
    return Column(
      children: [
        // "지난 시장 기록 보기" 버튼
        _buildCTAButton(
          responsive,
          textTheme,
          "지난 시장 기록 보기",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MarketHistoryScreen(),
              ),
            );
          },
        ),
        SizedBox(
          height: responsive.responsivePadding(mobilePadding: 12),
        ),
        // "저장한 가게"와 "찜한 음식" 버튼 (나란히)
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                responsive,
                textTheme,
                "저장한 가게",
                Icons.bookmark,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedStoresScreen(),
                    ),
                  );
                },
                showIcon: true,
              ),
            ),
            SizedBox(
              width: responsive.responsivePadding(mobilePadding: 12),
            ),
            Expanded(
              child: _buildActionButton(
                responsive,
                textTheme,
                "찜한 음식",
                Icons.favorite,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedFoodsScreen(),
                    ),
                  );
                },
                showIcon: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCTAButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    String label,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.softGreyBackground,
          foregroundColor: AppColors.mainText,
          padding: EdgeInsets.symmetric(
            vertical: responsive.responsivePadding(mobilePadding: 16) * 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 16),
            fontWeight: FontWeight.w600,
            color: AppColors.mainText,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool showIcon = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.softGreyBackground,
          foregroundColor: AppColors.mainText,
          padding: EdgeInsets.symmetric(
            vertical: responsive.responsivePadding(mobilePadding: 16) * 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(
                icon,
                size: responsive.responsiveIconSize(mobileSize: 24),
                color: AppColors.primary,
              ),
            if (showIcon)
              SizedBox(
                height: responsive.responsivePadding(mobilePadding: 8),
              ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 16),
                fontWeight: FontWeight.w600,
                color: AppColors.mainText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

