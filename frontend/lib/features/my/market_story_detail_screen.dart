// lib/features/my/market_story_detail_screen.dart

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../providers/auth_provider.dart";

class MarketStoryDetailScreen extends StatefulWidget {
  final String marketName;
  final int visitNumber;

  const MarketStoryDetailScreen({
    super.key,
    required this.marketName,
    required this.visitNumber,
  });

  @override
  State<MarketStoryDetailScreen> createState() =>
      _MarketStoryDetailScreenState();
}

class _MarketStoryDetailScreenState extends State<MarketStoryDetailScreen> {
  List<String> _reviewTags = []; // 리뷰 태그들
  List<MenuPhotoItem> _menuPhotos = []; // 사용자가 찍은 메뉴 사진들
  bool _isLoading = true;
  Map<String, bool> _likedMenus = {}; // 메뉴별 좋아요 상태

  @override
  void initState() {
    super.initState();
    _loadStoryDetail();
  }

  Future<void> _loadStoryDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: API 호출하여 시장 스토리 상세 정보 가져오기
      // final storyDetail = await _apiRepository.userService.getMarketStoryDetail(
      //   widget.marketName,
      //   widget.visitNumber,
      // );

      // 더미 데이터 (화면 확인용)
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _reviewTags = [
          "맛집 많음",
          "로컬 맛집",
          "관광 명소",
          "한적함",
          "인생샷",
          "아이 동반",
        ];

        _menuPhotos = [
          MenuPhotoItem(
            id: "1",
            photoUrl:
                "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%84%E1%85%A5%E1%86%A8%E1%84%87%E1%85%A9%E1%86%A9%E1%84%8B%E1%85%B5_ME155.png",
            recognizedMenuName: "Tteokbokki",
            isLiked: true,
          ),
          MenuPhotoItem(
            id: "2",
            photoUrl:
                "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%89%E1%85%AE%E1%86%AB%E1%84%83%E1%85%A2_ME166.png",
            recognizedMenuName: "Sundae",
            isLiked: false,
          ),
          MenuPhotoItem(
            id: "3",
            photoUrl:
                "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%92%E1%85%A9%E1%84%84%E1%85%A5%E1%86%A8_ME299.png",
            recognizedMenuName: "Hotteok",
            isLiked: true,
          ),
          MenuPhotoItem(
            id: "4",
            photoUrl:
                "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%83%E1%85%A1%E1%86%B0%E1%84%80%E1%85%A1%E1%86%BC%E1%84%8C%E1%85%A5%E1%86%BC_ME148.png",
            recognizedMenuName: "Dakgang",
            isLiked: false,
          ),
        ];

        // 초기 좋아요 상태 설정
        for (var photo in _menuPhotos) {
          _likedMenus[photo.id] = photo.isLiked;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("시장 스토리 상세 로드 실패: $e");
    }
  }

  void _toggleLike(String menuPhotoId) {
    setState(() {
      _likedMenus[menuPhotoId] = !(_likedMenus[menuPhotoId] ?? false);
    });
    // TODO: API 호출하여 좋아요 상태 업데이트
    // await _apiRepository.userService.toggleMenuLike(menuPhotoId);
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
                    // 제목
                    _buildTitle(responsive, textTheme, koreanName),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 20),
                    ),
                    // 리뷰 태그 칩들
                    _buildReviewTags(responsive, textTheme),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 32),
                    ),
                    // 메뉴판 섹션
                    _buildMenuSection(responsive, textTheme, koreanName),
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
        "$koreanName님과 ${widget.marketName} 시장 Story ${widget.visitNumber}",
        style: textTheme.headlineMedium?.copyWith(
          fontSize: responsive.responsiveFontSize(mobileSize: 20),
          fontWeight: FontWeight.w700,
          color: AppColors.mainText,
        ),
      ),
    );
  }

  Widget _buildReviewTags(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    // 한 줄에 최대 3개씩 배치
    final rows = <List<String>>[];
    for (int i = 0; i < _reviewTags.length; i += 3) {
      rows.add(_reviewTags.sublist(
        i,
        i + 3 > _reviewTags.length ? _reviewTags.length : i + 3,
      ));
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: responsive.responsivePadding(mobilePadding: 6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: row.asMap().entries.map((entry) {
                final index = entry.key;
                final tag = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < row.length - 1
                        ? responsive.responsivePadding(mobilePadding: 6)
                        : 0,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          responsive.responsivePadding(mobilePadding: 12) * 1.5,
                      vertical:
                          responsive.responsivePadding(mobilePadding: 8) * 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: responsive.responsiveFontSize(mobileSize: 12),
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    String koreanName,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 대제목
          Text(
            "$koreanName님의 메뉴판",
            style: textTheme.titleLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 18),
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 8),
          ),
          // 소제목
          Text(
            "맛있었다면 하트를 눌러보세요",
            style: textTheme.bodyMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 14),
              fontWeight: FontWeight.w400,
              color: AppColors.inactiveText,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 16),
          ),
          // 메뉴 사진 그리드 (한 줄에 2개)
          if (_menuPhotos.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: responsive.responsivePadding(mobilePadding: 40),
                ),
                child: Text(
                  "아직 등록된 메뉴가 없습니다",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 16),
                    fontWeight: FontWeight.w400,
                    color: AppColors.inactiveText,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing:
                    responsive.responsivePadding(mobilePadding: 12),
                mainAxisSpacing:
                    responsive.responsivePadding(mobilePadding: 16),
                childAspectRatio: 0.75,
              ),
              itemCount: _menuPhotos.length,
              itemBuilder: (context, index) {
                return _buildMenuPhotoCard(
                  responsive,
                  textTheme,
                  _menuPhotos[index],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMenuPhotoCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MenuPhotoItem menuPhoto,
  ) {
    final isLiked = _likedMenus[menuPhoto.id] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 사진
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                menuPhoto.photoUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFFF3EEF3));
                },
              ),
            ),
          ),
        ),
        SizedBox(
          height: responsive.responsivePadding(mobilePadding: 8),
        ),
        // 메뉴명
        Text(
          menuPhoto.recognizedMenuName,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 14),
            fontWeight: FontWeight.w500,
            color: AppColors.mainText,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: responsive.responsivePadding(mobilePadding: 4),
        ),
        // 하트 버튼
        GestureDetector(
          onTap: () {
            _toggleLike(menuPhoto.id);
          },
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: responsive.responsiveIconSize(mobileSize: 24),
            color: isLiked ? AppColors.primary : AppColors.inactiveText,
          ),
        ),
      ],
    );
  }
}

/// 메뉴 사진 아이템
class MenuPhotoItem {
  final String id;
  final String photoUrl; // 사용자가 찍은 사진 URL
  final String recognizedMenuName; // 모델이 인식한 메뉴명 (영문)
  final bool isLiked; // 초기 좋아요 상태

  MenuPhotoItem({
    required this.id,
    required this.photoUrl,
    required this.recognizedMenuName,
    this.isLiked = false,
  });
}

