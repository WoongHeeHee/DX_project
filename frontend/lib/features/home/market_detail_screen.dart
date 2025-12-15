// lib/features/home/market_detail_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../core/widgets/drag_only_scroll_behavior.dart";
import "../../core/widgets/google_map_widget.dart";
import "../../data/repositories/api_repository.dart";
import "../../data/models/market_models.dart" as api_models;
import "../../data/models/menu_models.dart";
import "models/market_model.dart";
import "models/food_model.dart";
import "constants/must_try_items.dart";

class MarketDetailScreen extends StatefulWidget {
  final MarketModel market;

  const MarketDetailScreen({super.key, required this.market});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  final _apiRepository = ApiRepository();
  int currentImageIndex = 0;
  bool _isLoading = false;
  String _userLocale = 'ko';
  
  // API로 가져온 데이터
  api_models.MarketInfoModel? _marketInfo;
  api_models.MarketModel? _market; // 좌표 정보 포함
  Map<String, MenuItemModel> _menuNameToModel = {}; // 메뉴 ID -> MenuItemModel 매핑 (변수명은 유지)
  BitmapDescriptor? _customPinIcon; // 커스텀 핀 아이콘

  @override
  void initState() {
    super.initState();
    _loadMarketData();
    // 첫 프레임 후 커스텀 핀 아이콘 로드 (context 사용 가능)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomPinIcon();
    });
  }

  /// 커스텀 핀 아이콘 로드
  Future<void> _loadCustomPinIcon() async {
    if (!mounted) return;
    
    // 일반 구글 핀 사용
    _customPinIcon = BitmapDescriptor.defaultMarker;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMarketData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 locale 가져오기
      final locale = await _apiRepository.userService.getLocale();
      
      // 시장 정보 조회 (좌표 정보 포함)
      final market = await _apiRepository.marketService.getMarket(widget.market.id);
      
      // 시장 부가정보 조회
      final marketInfo = await _apiRepository.marketService.getMarketInfo(widget.market.id);
      
      // 모든 메뉴를 가져와서 ID로 매핑
      final allMenus = await _apiRepository.menuService.getMenuItems(limit: 200);
      final menuIdToModel = <String, MenuItemModel>{};
      for (final menu in allMenus) {
        menuIdToModel[menu.id] = menu;
      }
      debugPrint("[MarketDetail] 총 메뉴 수: ${allMenus.length}, 매핑된 수: ${menuIdToModel.length}");
      
      if (mounted) {
        setState(() {
          _market = market;
          _marketInfo = marketInfo;
          _userLocale = locale;
          _menuNameToModel = menuIdToModel; // 실제로는 ID로 매핑
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("시장 데이터 로드 실패: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Colors.white, // #FFFFFF
        body: SafeArea(
          child: ScrollConfiguration(
            behavior: DragOnlyScrollBehavior(),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackButton(responsive),
              _buildImageCarousel(responsive, textTheme),
              _buildMarketInfo(responsive, textTheme),
              _buildMustTrySection(responsive, textTheme),
              _buildLocationSection(responsive, textTheme),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(ResponsiveHelper responsive) {
    return Container(
      padding: EdgeInsets.only(
        left: responsive.responsivePadding(mobilePadding: 16),
        right: responsive.responsivePadding(mobilePadding: 16),
        bottom: responsive.responsivePadding(mobilePadding: 8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.mainText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(ResponsiveHelper responsive, TextTheme textTheme) {
    final images = widget.market.imageUrls;
    final carouselHeight = responsive.isMobile ? 233.25 : 280.0;

    return Container(
      padding: EdgeInsets.all(
        responsive.responsivePadding(mobilePadding: 16),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // #FFFFFF - border가 보이지 않게 배경과 동일
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(
          responsive.responsivePadding(mobilePadding: 12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: carouselHeight,
            child: ScrollConfiguration(
              behavior: DragOnlyScrollBehavior(),
              child: PageView.builder(
                itemCount: images.length,
                onPageChanged: (index) {
                setState(() {
                  currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(
                    right: responsive.responsivePadding(mobilePadding: 8),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.imagePlaceholder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: AppColors.imagePlaceholder);
                      },
                    ),
                  ),
                );
              },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 페이지 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                width: index == currentImageIndex ? 14 : 6,
                height: 6,
                margin: EdgeInsets.symmetric(
                  horizontal: responsive.responsivePadding(mobilePadding: 3),
                ),
                decoration: BoxDecoration(
                  color: index == currentImageIndex
                      ? const Color(0xFF0F1724) // Figma 활성 색상
                      : const Color(0xFFF2F2F3), // Figma 비활성 색상
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildMarketInfo(ResponsiveHelper responsive, TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 16),
        vertical: responsive.responsivePadding(mobilePadding: 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.market.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: responsive.responsiveFontSize(
                mobileSize: 22,
                tabletSize: 24,
                desktopSize: 26,
              ),
              fontWeight: FontWeight.w600, // Semi Bold
              color: const Color(0xFF0F1724), // Figma 색상
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.market.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: responsive.responsiveFontSize(mobileSize: 14),
              fontWeight: FontWeight.w300, // Light
              color: const Color(0xFF0F1724), // Figma 색상
              height: 1.5,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 5)),
        ],
      ),
    );
  }

  Widget _buildMustTrySection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final mustTryMenuIds = mustTryItemsByMarket[widget.market.name] ?? [];
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 16),
        vertical: responsive.responsivePadding(mobilePadding: 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Must try",
            style: TextStyle(
              fontSize: responsive.responsiveFontSize(
                mobileSize: 16,
                tabletSize: 18,
                desktopSize: 20,
              ),
              fontWeight: FontWeight.w600, // Semi Bold
              color: const Color(0xFF111827), // Figma 색상
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          if (mustTryMenuIds.isEmpty)
            Text(
              "Must try 메뉴가 없습니다.",
              style: TextStyle(
                fontSize: responsive.responsiveFontSize(mobileSize: 12),
                fontWeight: FontWeight.w400, // Regular
                color: const Color(0xFF9CA3AF), // Figma 색상
                fontFamily: 'Inter',
              ),
            )
          else
            ...mustTryMenuIds.map((menuId) {
              final menuModel = _menuNameToModel[menuId];
              
              if (menuModel == null) {
                debugPrint("[MarketDetail] 메뉴 ID로 찾기 실패: $menuId");
                return const SizedBox.shrink();
              }
              
              // 메뉴 이름(한국어 원본)으로 이미지 경로 생성
              final baseName = menuModel.name;
              final imageUrl = _placeholderImage(baseName, menuId);
              final displayName = menuModel.getNameByLocale(_userLocale);
              
              return _buildMustTryItem(
                responsive,
                textTheme,
                MustTryItem(
                  id: menuId,
                  name: displayName,
                  description: '', // 설명은 무시
                  imageUrl: imageUrl,
                ),
                menuModel, // MenuItemModel 전달 (라우팅용)
              );
            }),
        ],
      ),
    );
  }

  String _placeholderImage(String name, String id, {int variant = 1}) {
    final encodedName = Uri.encodeComponent(name);
    final clamped = variant < 1 ? 1 : (variant > 3 ? 3 : variant);
    return "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/${encodedName}/${encodedName}${clamped}_${id}.png";
  }

  Widget _buildMustTryItem(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MustTryItem item,
    MenuItemModel menuModel,
  ) {
    return GestureDetector(
      onTap: () {
        // MenuItemModel을 FoodModel로 변환
        final food = _convertMenuItemToFoodModel(menuModel);
        context.push('/explore/food/${food.id}', extra: {'food': food});
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: responsive.responsivePadding(mobilePadding: 8),
        ),
        padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 8)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 (반응형 크기)
            Container(
              width: responsive.responsiveIconSize(mobileSize: 117),
              height: responsive.responsiveIconSize(mobileSize: 77),
              decoration: BoxDecoration(
                color: AppColors.imagePlaceholder,
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  item.imageUrl,
                  width: responsive.responsiveIconSize(mobileSize: 117),
                  height: responsive.responsiveIconSize(mobileSize: 77),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("[MarketDetail] 이미지 로드 실패: ${item.imageUrl}");
                    return Container(
                      width: responsive.responsiveIconSize(mobileSize: 117),
                      height: responsive.responsiveIconSize(mobileSize: 77),
                      color: AppColors.imagePlaceholder,
                    );
                  },
                ),
              ),
            ),
          SizedBox(width: responsive.responsivePadding(mobilePadding: 8)),
          // 메뉴 이름 (설명은 무시)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: responsive.responsivePadding(mobilePadding: 4),
              ),
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: responsive.responsiveFontSize(mobileSize: 13),
                  fontWeight: FontWeight.w500, // Medium
                  color: const Color(0xFF0F1724), // Figma 색상
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// MenuItemModel을 FoodModel로 변환 (라우팅용)
  FoodModel _convertMenuItemToFoodModel(MenuItemModel menu) {
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

  Widget _buildLocationSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 16),
        vertical: responsive.responsivePadding(mobilePadding: 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "오시는 길",
            style: TextStyle(
              fontSize: responsive.responsiveFontSize(
                mobileSize: 16,
                tabletSize: 18,
                desktopSize: 20,
              ),
              fontWeight: FontWeight.w600, // Semi Bold
              color: const Color(0xFF111827), // Figma 색상
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          // 지도 영역
          Container(
            width: double.infinity,
            height: responsive.isMobile ? 140 : 180,
            decoration: BoxDecoration(
              color: AppColors.imagePlaceholder,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildMapWidget(),
            ),
          ),
          const SizedBox(height: 12),
          // 정보 카드들 (API에서 가져온 데이터 사용, locale 반영)
          if (_marketInfo != null) ...[
            _buildInfoCard(
              responsive,
              textTheme,
              "영업 정보",
              _marketInfo!.openTime != null && _marketInfo!.closeTime != null
                  ? "${_marketInfo!.openTime} - ${_marketInfo!.closeTime}"
                  : widget.market.operatingHours,
            ),
            _buildInfoCard(
              responsive,
              textTheme,
              "주소",
              _marketInfo!.getAddressByLocale(_userLocale) ?? widget.market.address,
            ),
            _buildInfoCard(
              responsive,
              textTheme,
              "교통",
              _marketInfo!.getTransportByLocale(_userLocale) ?? widget.market.transportation,
            ),
            _buildInfoCard(
              responsive,
              textTheme,
              "주차",
              _marketInfo!.getParkingByLocale(_userLocale) ?? widget.market.parking,
            ),
            _buildInfoCard(
              responsive,
              textTheme,
              "화장실",
              _marketInfo!.getRestroomByLocale(_userLocale) ?? widget.market.restroom,
            ),
          ] else ...[
            _buildInfoCard(
              responsive,
              textTheme,
              "영업 정보",
              widget.market.operatingHours,
            ),
            _buildInfoCard(responsive, textTheme, "주소", widget.market.address),
            _buildInfoCard(
              responsive,
              textTheme,
              "교통",
              widget.market.transportation,
            ),
            _buildInfoCard(responsive, textTheme, "주차", widget.market.parking),
            _buildInfoCard(responsive, textTheme, "화장실", widget.market.restroom),
          ],
        ],
      ),
    );
  }

  /// 지도 위젯 빌드
  Widget _buildMapWidget() {
    // 좌표가 없는 경우 플레이스홀더 표시
    if (_market == null || _market!.lat == null || _market!.lng == null) {
      return Container(
        color: AppColors.imagePlaceholder,
        child: const Center(
          child: Text(
            '지도 정보가 없습니다',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 커스텀 핀 마커 생성
    final Set<Marker> markers = {};
    if (_customPinIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('market_location'),
          position: LatLng(_market!.lat!, _market!.lng!),
          icon: _customPinIcon!,
        ),
      );
    }

    // 1cm:200m 스케일에 맞는 줌 레벨 계산
    // 화면 너비가 대략 300px (약 10cm)라고 가정하면, 2km가 보여야 함
    // 줌 레벨 15는 약 1.2km, 줌 레벨 14는 약 2.4km
    // 더 정확하게는 2km를 보려면 줌 레벨 약 14.5
    const double zoomLevel = 14.5;

    return GoogleMapWidget(
      latitude: _market!.lat!,
      longitude: _market!.lng!,
      height: double.infinity,
      zoom: zoomLevel,
      markers: markers,
      interactive: false, // 모든 제스처 비활성화 (이동 및 확대/축소 불가)
      onMapCreated: (controller) {
        // 지도 생성 완료
      },
    );
  }

  Widget _buildInfoCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    String title,
    String content,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: responsive.responsivePadding(mobilePadding: 8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 10),
        vertical: responsive.responsivePadding(mobilePadding: 8),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(minHeight: 50), // Figma 높이
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.responsiveFontSize(mobileSize: 12),
              fontWeight: FontWeight.w500, // Medium
              color: const Color(0xFF111827), // Figma 색상
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            content.isNotEmpty ? content : '-',
            style: TextStyle(
              fontSize: responsive.responsiveFontSize(mobileSize: 12),
              fontWeight: FontWeight.w400, // Regular
              color: const Color(0xFF9CA3AF), // Figma 색상
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
