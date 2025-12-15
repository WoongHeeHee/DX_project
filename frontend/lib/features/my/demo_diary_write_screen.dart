// lib/features/my/demo_diary_write_screen.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../data/repositories/api_repository.dart";
import "gift_popup_dialog.dart";

/// 시연회용 임의 다이어리 작성 화면
class DemoDiaryWriteScreen extends StatefulWidget {
  const DemoDiaryWriteScreen({super.key});

  @override
  State<DemoDiaryWriteScreen> createState() => _DemoDiaryWriteScreenState();
}

class _DemoDiaryWriteScreenState extends State<DemoDiaryWriteScreen> {
  final _apiRepository = ApiRepository();
  Set<String> _selectedTags = {}; // 선택된 태그들
  List<DemoMenuPhotoItem> _menuPhotos = []; // 더미 메뉴 사진들
  bool _isLoading = true;
  Map<String, bool> _likedMenus = {}; // 메뉴별 좋아요 상태
  String? _marketId; // 시장 ID (LG DX 시장)

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
    _loadDemoData();
  }

  Future<void> _loadDemoData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // LG DX 시장 ID 찾기
      final markets = await _apiRepository.marketService.getMarkets();
      final lgDxMarket = markets.firstWhere(
        (m) => m.id == "MA0000" || m.name.contains("DX"),
        orElse: () => markets.first,
      );
      _marketId = lgDxMarket.id;

      // 더미 메뉴 사진 생성 (임의의 메뉴들)
      final demoMenus = [
        {"name": "떡볶이", "id": "ME155"},
        {"name": "김밥", "id": "ME012"},
        {"name": "닭강정", "id": "ME148"},
      ];

      final demoPhotos = demoMenus.map((menu) {
        final menuName = menu["name"]!;
        final menuId = menu["id"]!;
        final encodedName = Uri.encodeComponent(menuName);
        // placeholder 이미지 URL 생성
        final imageUrl = "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/$encodedName/${encodedName}1_$menuId.png";
        
        return DemoMenuPhotoItem(
          id: "demo_photo_${menuId}",
          photoUrl: imageUrl,
          recognizedMenuName: menuName,
          menuItemId: menuId,
        );
      }).toList();

      setState(() {
        _menuPhotos = demoPhotos;
        // 초기 좋아요 상태 설정
        for (var photo in _menuPhotos) {
          _likedMenus[photo.id] = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("데모 데이터 로드 실패: $e");
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

  void _toggleLike(String menuPhotoId) {
    setState(() {
      _likedMenus[menuPhotoId] = !(_likedMenus[menuPhotoId] ?? false);
    });
  }

  Future<void> _saveDiary() async {
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
      // 다이어리 생성 (더미 사진 ID는 빈 리스트로 전송 - 실제 저장하지 않음)
      await _apiRepository.diaryService.createDiary(
        marketId: _marketId!,
        keywords: _selectedTags.toList(),
        photoIds: [], // 임의 다이어리이므로 사진 ID는 빈 리스트
      );

      if (mounted) {
        // 다이어리 저장 성공 후 쿠폰 팝업 표시
        GiftPopupDialog.show(
          context,
          onShowFloatingButton: () {
            // 팝업 닫기 후 아무 동작도 하지 않음 (마이페이지가 아니므로)
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("다이어리 저장 실패: $e"),
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
                    // 안내 문구
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
                    _buildMenuSection(responsive, textTheme),
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
        "시연회용 임의 다이어리 작성 화면입니다.",
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
        "LG DX 시장 어떠셨나요? 함께 추억을 남겨요!",
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
    final rows = <List<ReviewTagOption>>[];

    // 처음 6개는 3개씩 배치
    for (int i = 0; i < 6; i += 3) {
      rows.add(_reviewTagOptions.sublist(i, i + 3));
    }

    // 다음 2개는 한 줄에
    rows.add(_reviewTagOptions.sublist(6, 8));

    // 다음 2개는 한 줄에
    rows.add(_reviewTagOptions.sublist(8, 10));

    // 마지막 2개는 한 줄에
    rows.add(_reviewTagOptions.sublist(10, 12));

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
            "메뉴판",
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
    DemoMenuPhotoItem menuPhoto,
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
          onPressed: _saveDiary,
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
            "LG DX 시장 저장하기",
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

/// 더미 메뉴 사진 아이템
class DemoMenuPhotoItem {
  final String id;
  final String photoUrl;
  final String recognizedMenuName;
  final String? menuItemId;

  DemoMenuPhotoItem({
    required this.id,
    required this.photoUrl,
    required this.recognizedMenuName,
    this.menuItemId,
  });
}

