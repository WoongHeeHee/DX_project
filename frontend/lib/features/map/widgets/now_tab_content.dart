// lib/features/map/widgets/now_tab_content.dart

import "package:flutter/material.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/widgets/responsive_padding.dart";
import "../../../data/repositories/api_repository.dart";
import "../../../data/models/menu_models.dart";
import "../../../data/services/market_photo_service.dart";
import "../../home/models/market_model.dart";
import "../../home/models/food_model.dart";
import "must_eat_section.dart";
import "feed_header.dart";
import "feed_image_slider.dart";
import "action_buttons.dart";

/// NOW 탭 콘텐츠 위젯
class NowTabContent extends StatefulWidget {
  final MarketModel market;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const NowTabContent({
    super.key,
    required this.market,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<NowTabContent> createState() => _NowTabContentState();
}

class _NowTabContentState extends State<NowTabContent> {
  final _apiRepository = ApiRepository();
  MenuItemModel? _selectedMenuItem;
  bool _isLoadingMenuItem = false;
  String _userLocale = 'ko';

  @override
  void initState() {
    super.initState();
    _loadUserLocale();
  }

  Future<void> _loadUserLocale() async {
    try {
      final locale = await _apiRepository.userService.getLocale();
      if (mounted) {
        setState(() {
          _userLocale = locale;
        });
      }
    } catch (e) {
      debugPrint("locale 조회 실패, 기본값 사용: $e");
    }
  }

  Future<void> _loadMenuItem(String? menuItemId) async {
    if (menuItemId == null || menuItemId.isEmpty) {
      setState(() {
        _selectedMenuItem = null;
        _isLoadingMenuItem = false;
      });
      return;
    }

    setState(() {
      _isLoadingMenuItem = true;
    });

    try {
      final menuItem = await _apiRepository.menuService.getMenuItem(menuItemId);
      if (mounted) {
        setState(() {
          _selectedMenuItem = menuItem;
          _isLoadingMenuItem = false;
        });
      }
    } catch (e) {
      debugPrint("메뉴 정보 로드 실패: $e");
      if (mounted) {
        setState(() {
          _selectedMenuItem = null;
          _isLoadingMenuItem = false;
        });
      }
    }
  }

  void _onPhotoChanged(MarketPhoto? photo) {
    _loadMenuItem(photo?.menuItemId);
  }

  String _getSpicinessDescription(int level) {
    final descriptions = [
      "안 매워요",
      "김치보다 안 매워요",
      "김치만큼 매워요",
      "불닭보다 안 매워요",
      "불닭만큼 매워요",
    ];
    return descriptions[level.clamp(1, 5) - 1];
  }

  FoodModel? _convertMenuItemToFoodModel(MenuItemModel? menu) {
    if (menu == null) return null;

    final locale = _userLocale;
    final baseName = menu.name; // 이미지 경로는 항상 ko 이름 사용
    final contains = (menu.getContainsByLocale(locale) ?? '')
        .split(RegExp(r',\s*'))
        .where((e) => e.isNotEmpty)
        .toList();
    final mayContains = (menu.getMayContainsByLocale(locale) ?? '')
        .split(RegExp(r',\s*'))
        .where((e) => e.isNotEmpty)
        .toList();
    final similarText = menu.getSimilarFoodByLocale(locale);
    final similarFoods = <SimilarFood>[
      if (similarText != null && similarText.trim().isNotEmpty)
        SimilarFood(
          id: "similar_${menu.id}",
          name: similarText.trim(),
          description: "",
        ),
    ];

    // 3장의 플레이스홀더(variant 1~3) 생성
    final imageUrls = List.generate(
      3,
      (i) => _placeholderImage(baseName, menu.id, variant: i + 1),
    );

    return FoodModel(
      id: menu.id,
      name: menu.getNameByLocale(locale),
      baseName: baseName,
      category: menu.category ?? "Meals",
      imageUrl: imageUrls.first,
      description: menu.getDescriptionByLocale(locale) ?? '',
      imageUrls: imageUrls,
      spiciness: menu.spiceLevel,
      spicinessDescription: _getSpicinessDescription(menu.spiceLevel),
      similarFoods: similarFoods,
      contains: contains,
      mayContain: mayContains,
    );
  }

  String _placeholderImage(String name, String id, {int variant = 1}) {
    final encodedName = Uri.encodeComponent(name);
    final clamped = variant < 1 ? 1 : (variant > 3 ? 3 : variant);
    return "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/${encodedName}/${encodedName}${clamped}_${id}.png";
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Must eat 섹션
          MustEatSection(market: widget.market),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 피드 섹션 (제목과 필터)
          FeedHeader(
            marketName: widget.market.name,
            selectedFilter: widget.selectedFilter,
            onFilterChanged: widget.onFilterChanged,
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 피드 이미지 영역 (전체 너비)
          FeedImageSlider(
            marketId: widget.market.id,
            selectedFilter: widget.selectedFilter,
            onPhotoChanged: _onPhotoChanged,
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 버튼들
          ActionButtons(
            market: widget.market,
            selectedMenuItem: _selectedMenuItem,
            selectedFood: _convertMenuItemToFoodModel(_selectedMenuItem),
            isLoading: _isLoadingMenuItem,
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
        ],
      ),
    );
  }
}

