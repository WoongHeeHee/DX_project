// lib/features/my/market_review_write_screen.dart

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../providers/auth_provider.dart";
import "../../data/repositories/api_repository.dart";

class MarketReviewWriteScreen extends StatefulWidget {
  final String marketName;

  const MarketReviewWriteScreen({
    super.key,
    required this.marketName,
  });

  @override
  State<MarketReviewWriteScreen> createState() =>
      _MarketReviewWriteScreenState();
}

class _MarketReviewWriteScreenState extends State<MarketReviewWriteScreen> {
  final _apiRepository = ApiRepository();
  Set<String> _selectedTags = {}; // 선택된 태그들
  List<MenuPhotoItem> _menuPhotos = []; // 사용자가 찍은 메뉴 사진들
  bool _isLoading = true;
  Map<String, bool> _likedMenus = {}; // 메뉴별 좋아요 상태 (photo_id -> isLiked)
  Map<String, String> _photoIdToMenuItemId = {}; // photo_id -> menu_item_id 매핑
  String? _marketId; // 시장 ID

  // 리뷰 태그 옵션들 (아이콘 포함)
  final List<ReviewTagOption> _reviewTagOptions = [
    ReviewTagOption(
      id: "맛집 많음",
      label: "맛집 많음",
      icon: Icons.restaurant,
    ),
    ReviewTagOption(
      id: "로컬 맛집",
      label: "로컬 맛집",
      icon: Icons.local_dining,
    ),
    ReviewTagOption(
      id: "관광 명소",
      label: "관광 명소",
      icon: Icons.camera_alt,
    ),
    ReviewTagOption(
      id: "한적함",
      label: "한적함",
      icon: Icons.nature,
    ),
    ReviewTagOption(
      id: "인생샷",
      label: "인생샷",
      icon: Icons.photo_camera,
    ),
    ReviewTagOption(
      id: "아이 동반",
      label: "아이 동반",
      icon: Icons.child_care,
    ),
    ReviewTagOption(
      id: "부모님 동반",
      label: "부모님 동반",
      icon: Icons.family_restroom,
    ),
    ReviewTagOption(
      id: "대중교통 편리",
      label: "대중교통 편리",
      icon: Icons.directions_transit,
    ),
    ReviewTagOption(
      id: "주차 편리",
      label: "주차 편리",
      icon: Icons.local_parking,
    ),
    ReviewTagOption(
      id: "자전거 편리",
      label: "자전거 편리",
      icon: Icons.pedal_bike,
    ),
    ReviewTagOption(
      id: "휠체어 접근",
      label: "휠체어 접근",
      icon: Icons.accessible,
    ),
    ReviewTagOption(
      id: "유모차 편리",
      label: "유모차 편리",
      icon: Icons.baby_changing_station,
    ),
    ReviewTagOption(
      id: "친절함",
      label: "친절함",
      icon: Icons.favorite,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  Future<void> _loadReviewData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 시장 이름으로 시장 ID 찾기
      final markets = await _apiRepository.marketService.getMarkets();
      final market = markets.firstWhere(
        (m) => m.name == widget.marketName,
        orElse: () => markets.first, // 찾지 못하면 첫 번째 시장 사용
      );
      _marketId = market.id;

      // 시장별 사용자 사진 조회
      final marketPhotos = await _apiRepository.diaryService.getMarketPhotos(_marketId!);

      // MenuPhotoItem으로 변환
      final menuPhotoItems = marketPhotos.map((photo) {
        // photo_id를 menu_item_id로 매핑 (좋아요 API 호출용)
        if (photo.menuItemId != null) {
          _photoIdToMenuItemId[photo.id] = photo.menuItemId!;
        }
        return MenuPhotoItem(
          id: photo.id,
          photoUrl: photo.photoUrl,
          recognizedMenuName: photo.recognizedMenuName,
          isLiked: photo.isLiked,
        );
      }).toList();

      setState(() {
        _menuPhotos = menuPhotoItems;

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
      debugPrint("리뷰 데이터 로드 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("데이터 로드 실패: $e"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTags.contains(tagId)) {
        _selectedTags.remove(tagId);
      } else {
        _selectedTags.add(tagId);
      }
    });
  }

  Future<void> _toggleLike(String menuPhotoId) async {
    final currentLikeState = _likedMenus[menuPhotoId] ?? false;
    
    setState(() {
      _likedMenus[menuPhotoId] = !currentLikeState;
    });

    try {
      // 사진에서 메뉴 아이템 ID 찾기
      final menuItemId = _photoIdToMenuItemId[menuPhotoId];
      if (menuItemId == null) {
        debugPrint("메뉴 아이템 ID를 찾을 수 없습니다: $menuPhotoId");
        // 실패 시 원래 상태로 복구
        setState(() {
          _likedMenus[menuPhotoId] = currentLikeState;
        });
        return;
      }
      
      // 좋아요 API 호출
      if (!currentLikeState) {
        await _apiRepository.diaryService.addLike(menuItemId: menuItemId);
      } else {
        await _apiRepository.diaryService.removeLike(menuItemId: menuItemId);
      }
    } catch (e) {
      // 실패 시 원래 상태로 복구
      setState(() {
        _likedMenus[menuPhotoId] = currentLikeState;
      });
      debugPrint("좋아요 토글 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("좋아요 처리 실패: $e"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _saveReview() async {
    if (_marketId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("시장 정보를 찾을 수 없습니다"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      return;
    }

    if (_selectedTags.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("최소 하나의 태그를 선택해주세요"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      return;
    }

    try {
      // 다이어리 생성 (키워드는 태그로 사용)
      await _apiRepository.diaryService.createDiary(
        marketId: _marketId!,
        keywords: _selectedTags.toList(),
        photoIds: _menuPhotos.map((p) => p.id).toList(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // 리뷰 작성 완료 플래그 전달
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("리뷰 저장 실패: $e"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
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
                    _buildTitle(responsive, textTheme),
                    // 안내 문구 (회색 작은 글씨) - 대제목 아래, 메뉴판과 동일한 패딩
                    _buildNoticeText(responsive, textTheme),
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
                      height: responsive.responsivePadding(mobilePadding: 32),
                    ),
                    // 저장하기 버튼
                    _buildSaveButton(responsive, textTheme),
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

  Widget _buildNoticeText(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: responsive.responsivePadding(mobilePadding: 8),
        left: responsive.responsivePadding(mobilePadding: 20),
        right: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: Text(
        "AI가 방문 기록을 만들어드려요. 방문 후 7일 안에 작성해주세요.",
        style: textTheme.bodySmall?.copyWith(
          fontSize: responsive.responsiveFontSize(mobileSize: 12),
          fontWeight: FontWeight.w400,
          color: AppColors.inactiveText,
        ),
      ),
    );
  }

  Widget _buildTitle(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: responsive.responsivePadding(mobilePadding: 8),
        left: responsive.responsivePadding(mobilePadding: 20),
        right: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: Text(
        "${widget.marketName} 어떠셨나요? 함께 추억을 남겨요!",
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
    // 주차 편리(인덱스 8), 유모차 편리(인덱스 11), 친절함(인덱스 12)을 마지막 줄에 함께 배치하여 오버플로우 방지
    final rows = <List<ReviewTagOption>>[];

    // 처음 6개는 3개씩 배치 (맛집 많음 ~ 아이 동반)
    for (int i = 0; i < 6; i += 3) {
      rows.add(_reviewTagOptions.sublist(i, i + 3));
    }

    // 다음 2개는 한 줄에 (부모님 동반, 대중교통 편리)
    rows.add(_reviewTagOptions.sublist(6, 8));

    // 다음 2개는 한 줄에 (자전거 편리, 휠체어 접근)
    rows.add(_reviewTagOptions.sublist(9, 11));

    // 마지막 3개는 한 줄에 (주차 편리, 유모차 편리, 친절함)
    rows.add([
      _reviewTagOptions[8], // 주차 편리
      _reviewTagOptions[11], // 유모차 편리
      _reviewTagOptions[12], // 친절함
    ]);

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
                final tagOption = entry.value;
                final isSelected = _selectedTags.contains(tagOption.id);

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < row.length - 1
                        ? responsive.responsivePadding(mobilePadding: 6)
                        : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      _toggleTag(tagOption.id);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            responsive.responsivePadding(mobilePadding: 12) *
                                1.5,
                        vertical:
                            responsive.responsivePadding(mobilePadding: 8) *
                                1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tagOption.icon,
                            size: responsive.responsiveIconSize(mobileSize: 16),
                            color: isSelected
                                ? AppColors.white
                                : AppColors.mainText,
                          ),
                          SizedBox(
                            width:
                                responsive.responsivePadding(mobilePadding: 4),
                          ),
                          Text(
                            tagOption.label,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize:
                                  responsive.responsiveFontSize(mobileSize: 12),
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.mainText,
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(
                              width: responsive.responsivePadding(
                                  mobilePadding: 4),
                            ),
                            GestureDetector(
                              onTap: () {
                                _toggleTag(tagOption.id);
                              },
                              child: Icon(
                                Icons.close,
                                size: responsive.responsiveIconSize(
                                    mobileSize: 16),
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ],
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
          onTap: () async {
            await _toggleLike(menuPhoto.id);
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

  Widget _buildSaveButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(
              vertical: responsive.responsivePadding(mobilePadding: 16) * 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Text(
            "${widget.marketName} 저장하기",
            style: textTheme.titleMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 16),
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// 리뷰 태그 옵션
class ReviewTagOption {
  final String id;
  final String label;
  final IconData icon;

  ReviewTagOption({
    required this.id,
    required this.label,
    required this.icon,
  });
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

