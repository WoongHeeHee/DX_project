// lib/features/my/market_history_screen.dart

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../providers/auth_provider.dart";
import "../home/models/market_model.dart";
import "market_story_detail_screen.dart";

class MarketHistoryScreen extends StatefulWidget {
  const MarketHistoryScreen({super.key});

  @override
  State<MarketHistoryScreen> createState() => _MarketHistoryScreenState();
}

class _MarketHistoryScreenState extends State<MarketHistoryScreen> {
  List<MustTryItem> _top3Foods = []; // 제일 맛있게 먹은 음식 TOP 3
  List<MarketHistoryItem> _marketHistories = []; // 지난 한국 시장 탐방 기록
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarketHistory();
  }

  Future<void> _loadMarketHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: API 호출하여 제일 맛있게 먹은 음식 TOP 3 가져오기
      // final top3Foods = await _apiRepository.userService.getTop3FavoriteFoods();

      // TODO: API 호출하여 지난 한국 시장 탐방 기록 가져오기
      // final histories = await _apiRepository.userService.getMarketHistories();

      // 더미 데이터 (화면 확인용)
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _top3Foods = [
          MustTryItem(
            id: "1",
            name: "떡볶이",
            description: "",
            imageUrl:
                "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%84%E1%85%A5%E1%86%A8%E1%84%87%E1%85%A9%E1%86%A9%E1%84%8B%E1%85%B5_ME155.png",
          ),
          MustTryItem(
            id: "2",
            name: "닭강정",
            description: "",
            imageUrl:
                "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%83%E1%85%A1%E1%86%B0%E1%84%80%E1%85%A1%E1%86%BC%E1%84%8C%E1%85%A5%E1%86%BC_ME148.png",
          ),
          MustTryItem(
            id: "3",
            name: "구운옥수수",
            description: "",
            imageUrl:
                "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%80%E1%85%AE%E1%84%8B%E1%85%AE%E1%86%AB%E1%84%8B%E1%85%A9%E1%86%A8%E1%84%89%E1%85%AE%E1%84%89%E1%85%AE_ME131.png",
          ),
        ];

        _marketHistories = [
          MarketHistoryItem(
            id: "1",
            marketName: "망원시장",
            visitNumber: 1,
            visitedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ];

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("시장 기록 로드 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final koreanName = user?.koreanName ?? "김가희";

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    _buildHeader(responsive, textTheme),
                    // 대제목
                    _buildTitle(responsive, textTheme, koreanName),
                    // 제일 맛있게 먹은 음식 TOP 3
                    _buildTop3FoodsSection(responsive, textTheme),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 32),
                    ),
                    // 지난 한국 시장 탐방 기록
                    _buildMarketHistorySection(responsive, textTheme),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 20),
                    ),
                  ],
                ),
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
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.chevron_left,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.mainText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    String koreanName,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: Text(
        "$koreanName님의 한국 시장 Story",
        style: textTheme.headlineMedium?.copyWith(
          fontSize: responsive.responsiveFontSize(mobileSize: 24),
          fontWeight: FontWeight.w700,
          color: AppColors.mainText,
        ),
      ),
    );
  }

  Widget _buildTop3FoodsSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: responsive.responsivePadding(mobilePadding: 32),
        left: responsive.responsivePadding(mobilePadding: 20),
        right: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 부제목
          Text(
            "제일 맛있게 먹은 음식 TOP 3",
            style: textTheme.titleLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 18),
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 16),
          ),
          // Must eat 섹션 (지도 탭의 NOW의 Must eat과 동일한 스타일)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              responsive.responsivePadding(mobilePadding: 12),
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _top3Foods.take(3).map((item) {
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEF3),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(color: const Color(0xFFF3EEF3));
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 6),
                      ),
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize:
                              responsive.responsiveFontSize(mobileSize: 13),
                          fontWeight: FontWeight.w500,
                          color: AppColors.mainText,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketHistorySection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 부제목
          Text(
            "지난 한국 시장 탐방 기록",
            style: textTheme.titleLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 18),
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 16),
          ),
          // 시장 기록 카드 리스트
          if (_marketHistories.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: responsive.responsivePadding(mobilePadding: 40),
                ),
                child: Text(
                  "아직 방문한 시장이 없습니다",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 16),
                    fontWeight: FontWeight.w400,
                    color: AppColors.inactiveText,
                  ),
                ),
              ),
            )
          else
            ..._marketHistories.map((history) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: responsive.responsivePadding(mobilePadding: 12),
                ),
                child: _buildMarketHistoryCard(responsive, textTheme, history),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildMarketHistoryCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MarketHistoryItem history,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketStoryDetailScreen(
              marketName: history.marketName,
              visitNumber: history.visitNumber,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          responsive.responsivePadding(mobilePadding: 16),
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${history.marketName} Story ${history.visitNumber}",
              style: textTheme.titleMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 16),
                fontWeight: FontWeight.w600,
                color: AppColors.mainText,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.inactiveText,
            ),
          ],
        ),
      ),
    );
  }
}

/// 시장 탐방 기록 아이템
class MarketHistoryItem {
  final String id;
  final String marketName; // 시장 이름
  final int visitNumber; // 방문 횟수 (같은 시장을 두번 방문하면 2가 됨)
  final DateTime visitedAt; // 방문 날짜

  MarketHistoryItem({
    required this.id,
    required this.marketName,
    required this.visitNumber,
    required this.visitedAt,
  });
}

