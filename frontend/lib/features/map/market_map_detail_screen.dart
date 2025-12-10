// lib/features/map/market_map_detail_screen.dart

import "dart:async";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/google_map_widget.dart";
import "../../data/repositories/api_repository.dart";
import "../home/models/market_model.dart";
import "models/store_model.dart";

// 웹에서 JavaScript 함수 호출을 위한 import
import 'dart:js' as js;

class MarketMapDetailScreen extends StatefulWidget {
  final MarketModel market;

  const MarketMapDetailScreen({super.key, required this.market});

  @override
  State<MarketMapDetailScreen> createState() => _MarketMapDetailScreenState();
}

class _MarketMapDetailScreenState extends State<MarketMapDetailScreen> {
  bool _isNowTab = true;
  String _selectedFilter = "전체";
  late DraggableScrollableController _draggableController;
  Timer? _snapTimer;
  double _lastSize = 0.4;
  List<StoreModel> _savedStores = []; // 저장된 가게 리스트
  final _apiRepository = ApiRepository();
  GoogleMapController? _mapController;
  Set<Marker> _photoMarkers = {};

  // 스냅 포인트: 최소, 중간, 최대
  static const double _minSize = 0.1; // 인디케이터만 보일 정도
  static const double _midSize = 0.4; // 디폴트: 화면의 2/5
  static const double _maxSize = 0.95; // 거의 전체 화면

  @override
  void initState() {
    super.initState();
    _draggableController = DraggableScrollableController();
    _draggableController.addListener(_onDragUpdate);
    _lastSize = _midSize;
    _savedStores = _getSavedStoresForMarket();
    _loadPhotoLocations();
    
    // 초기 바텀시트 상태를 JavaScript에 전달
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBottomSheetState(_midSize);
    });
  }

  Future<void> _loadPhotoLocations() async {
    if (_isNowTab) {
      try {
        final response = await _apiRepository.marketPhotoService.getMarketPhotoLocations(
          marketId: widget.market.id,
          limit: 10,
        );
        
        final markers = <Marker>{};
        for (var i = 0; i < response.locations.length; i++) {
          final location = response.locations[i];
          markers.add(
            Marker(
              markerId: MarkerId('photo_${location.photoId}'),
              position: LatLng(location.lat, location.lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
        
        setState(() {
          _photoMarkers = markers;
        });
      } catch (e) {
        debugPrint("사진 위치 로드 실패: $e");
      }
    }
  }

  void _moveToStoreLocation(StoreModel store) {
    // TODO: 실제 가게 좌표를 사용하여 지도 이동
    // 현재는 더미 좌표 사용
    final lat = 37.5665;
    final lng = 126.9780;
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17.0),
    );
  }

  // 시장별 저장된 가게 리스트 가져오기 (더미 데이터)
  List<StoreModel> _getSavedStoresForMarket() {
    // 각 시장별로 다른 저장된 가게 리스트 반환
    // TODO: 실제로는 widget.market.name을 사용하여 시장별로 다른 데이터 반환
    return [
      StoreModel(
        id: "saved_1",
        name: "가게명1",
        imageUrls: ["https://placehold.co/110x110"],
        address: "서울특별시 마포구 망원동",
        status: StoreStatus.open,
        isSaved: true,
        operatingHours: "영업시간 Lorem ipsum",
        closedDays: "휴무일 Lorem ipsum",
      ),
      StoreModel(
        id: "saved_2",
        name: "가게명2",
        imageUrls: ["https://placehold.co/110x110"],
        address: "서울특별시 마포구 망원동",
        status: StoreStatus.closingSoon,
        isSaved: true,
        operatingHours: "영업시간 Lorem ipsum",
        closedDays: "휴무일 Lorem ipsum",
      ),
      StoreModel(
        id: "saved_3",
        name: "가게명3",
        imageUrls: ["https://placehold.co/110x110"],
        address: "서울특별시 마포구 망원동",
        status: StoreStatus.open,
        isSaved: true,
        operatingHours: "영업시간 Lorem ipsum",
        closedDays: "휴무일 Lorem ipsum",
      ),
    ];
  }

  @override
  void dispose() {
    _snapTimer?.cancel();
    _draggableController.removeListener(_onDragUpdate);
    _draggableController.dispose();
    super.dispose();
  }

  void _onDragUpdate() {
    if (!_draggableController.isAttached) return;

    final currentSize = _draggableController.size;

    // JavaScript에 바텀시트 상태 전달 (웹에서만)
    _updateBottomSheetState(currentSize);

    // 크기가 변경되면 타이머 리셋
    if ((currentSize - _lastSize).abs() > 0.01) {
      _lastSize = currentSize;
      _snapTimer?.cancel();

      // 드래그가 멈춘 후 100ms 후에 스냅
      _snapTimer = Timer(const Duration(milliseconds: 50), () {
        if (!_draggableController.isAttached) return;

        final finalSize = _draggableController.size;
        final snapSize = _getNearestSnapPoint(finalSize);

        if ((finalSize - snapSize).abs() > 0.05) {
          // 5% 이상 차이가 나면 스냅
          _draggableController.animateTo(
            snapSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// 바텀시트 상태를 JavaScript에 전달하여 지도 제스처 차단
  void _updateBottomSheetState(double size) {
    if (kIsWeb) {
      try {
        final isOpen = size > _minSize;
        js.context.callMethod('setBottomSheetState', [isOpen, size]);
      } catch (e) {
        debugPrint('JavaScript 함수 호출 실패: $e');
      }
    }
  }

  double _getNearestSnapPoint(double currentSize) {
    final snapPoints = [_minSize, _midSize, _maxSize];
    double nearest = _midSize;
    double minDistance = double.infinity;

    for (final point in snapPoints) {
      final distance = (currentSize - point).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = point;
      }
    }

    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // 지도 (전체 화면)
          GoogleMapWidget(
            latitude: 37.5665,
            longitude: 126.9780,
            address: widget.market.address,
            placeName: widget.market.name,
            height: MediaQuery.of(context).size.height,
            markers: _photoMarkers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            zoom: 15.0,
          ),
          // 뒤로가기 버튼
          _buildBackButton(responsive),
          // 드래그 가능한 바텀시트
          DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: _midSize, // 디폴트: 화면의 40% (2-1)
            minChildSize: _minSize, // 최소: 핸들바만 보임 (2-3)
            maxChildSize: _maxSize, // 최대: 거의 전체 화면 (2-2)
            snap: true, // 스냅 기능 활성화
            snapSizes: const [_minSize, _midSize, _maxSize], // 스냅 포인트 명시
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // 인디케이터
                    _buildIndicator(),
                    // 바텀시트 내용
                    Expanded(
                      child: _buildBottomSheetContent(
                        responsive,
                        textTheme,
                        scrollController,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(ResponsiveHelper responsive) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(
          responsive.responsivePadding(mobilePadding: 16),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.mainText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.subText.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildBottomSheetContent(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    ScrollController scrollController,
  ) {
    return GestureDetector(
      // 바텀시트 내부에서 모든 제스처를 가로채서 지도로 전파되지 않도록 함
      // scale은 pan의 상위 집합이므로 scale만 사용
      onScaleStart: (_) {},
      onScaleUpdate: (_) {},
      onScaleEnd: (_) {},
      child: NotificationListener<ScrollNotification>(
        // 스크롤 이벤트를 가로채서 지도로 전파되지 않도록 함
        onNotification: (notification) {
          // 스크롤 이벤트를 소비하여 지도로 전파되지 않도록 함
          return true;
        },
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NOW/SAVED 탭
              _buildTabSelector(responsive, textTheme),
              // 컨텐츠 영역
              _isNowTab
                  ? _buildNowContent(responsive, textTheme)
                  : _buildSavedContent(responsive, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEF3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isNowTab = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isNowTab ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "NOW",
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 13),
                      fontWeight: FontWeight.w500,
                      color: _isNowTab
                          ? AppColors.mainText
                          : AppColors.inactiveText,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isNowTab = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: !_isNowTab ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "SAVED",
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 13),
                      fontWeight: FontWeight.w500,
                      color: !_isNowTab
                          ? AppColors.mainText
                          : AppColors.inactiveText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MustTryItem> _getDefaultMustTryItems() {
    final marketName = widget.market.name;

    if (marketName.contains("광장")) {
      return [
        MustTryItem(
          id: "1",
          name: "꼬마김밥",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
        ),
        MustTryItem(
          id: "2",
          name: "빈대떡",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%83%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
        ),
        MustTryItem(
          id: "3",
          name: "육회",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
        ),
      ];
    } else if (marketName.contains("망원")) {
      return [
        MustTryItem(
          id: "1",
          name: "떡볶이",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%84%E1%85%A5%E1%86%A8%E1%84%87%E1%85%A9%E1%86%A9%E1%84%8B%E1%85%B5_ME155.png",
        ),
        MustTryItem(
          id: "2",
          name: "닭강정",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%83%E1%85%A1%E1%86%B0%E1%84%80%E1%85%A1%E1%86%BC%E1%84%8C%E1%85%A5%E1%86%BC_ME148.png",
        ),
        MustTryItem(
          id: "3",
          name: "구운옥수수",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EB%A7%9D%EC%9B%90%EC%8B%9C%EC%9E%A5_%E1%84%80%E1%85%AE%E1%84%8B%E1%85%AE%E1%86%AB%E1%84%8B%E1%85%A9%E1%86%A8%E1%84%89%E1%85%AE%E1%84%89%E1%85%AE_ME131.png",
        ),
      ];
    } else if (marketName.contains("통인")) {
      return [
        MustTryItem(
          id: "1",
          name: "기름떡볶이",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%ED%86%B5%EC%9D%B8%EC%8B%9C%EC%9E%A5_%E1%84%80%E1%85%B5%E1%84%85%E1%85%B3%E1%86%B7%E1%84%84%E1%85%A5%E1%86%A8%E1%84%87%E1%85%A9%E1%86%A9%E1%84%8B%E1%85%B5_ME134.png",
        ),
        MustTryItem(
          id: "2",
          name: "닭꼬치",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%ED%86%B5%EC%9D%B8%EC%8B%9C%EC%9E%A5_%E1%84%83%E1%85%A1%E1%86%B0%E1%84%81%E1%85%A9%E1%84%8E%E1%85%B5_ME149.png",
        ),
        MustTryItem(
          id: "3",
          name: "모둠전",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%ED%86%B5%EC%9D%B8%EC%8B%9C%EC%9E%A5_%E1%84%86%E1%85%A9%E1%84%83%E1%85%AE%E1%86%B7%E1%84%8C%E1%85%A5%E1%86%AB_ME166.png",
        ),
      ];
    } else if (marketName.contains("서울풍물") || marketName.contains("풍물")) {
      return [
        MustTryItem(
          id: "1",
          name: "녹두전",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EC%84%9C%EC%9A%B8%ED%92%8D%EB%AC%BC%EC%8B%9C%EC%9E%A5_%E1%84%82%E1%85%A9%E1%86%A8%E1%84%83%E1%85%AE%E1%84%8C%E1%85%A5%E1%86%AB_ME147.png",
        ),
        MustTryItem(
          id: "2",
          name: "소머리국밥",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EC%84%9C%EC%9A%B8%ED%92%8D%EB%AC%BC%EC%8B%9C%EC%9E%A5_%E1%84%89%E1%85%A9%E1%84%86%E1%85%A5%E1%84%85%E1%85%B5%E1%84%80%E1%85%AE%E1%86%A8%E1%84%87%E1%85%A1%E1%86%B8_ME343.png",
        ),
        MustTryItem(
          id: "3",
          name: "호떡",
          description: "",
          imageUrl:
              "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EC%84%9C%EC%9A%B8%ED%92%8D%EB%AC%BC%EC%8B%9C%EC%9E%A5_%E1%84%92%E1%85%A9%E1%84%84%E1%85%A5%E1%86%A8_ME299.png",
        ),
      ];
    }

    // 기본값 (다른 시장의 경우)
    return [
      MustTryItem(
        id: "1",
        name: "꼬마김밥",
        description: "",
        imageUrl:
            "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%EA%BC%AC%EB%A7%88%EA%B9%80%EB%B0%A5_ME016.png",
      ),
      MustTryItem(
        id: "2",
        name: "빈대떡",
        description: "",
        imageUrl:
            "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%87%E1%85%B5%E1%86%AB%E1%84%83%E1%85%A2%E1%84%84%E1%85%A5%E1%86%A8_ME175.png",
      ),
      MustTryItem(
        id: "3",
        name: "육회",
        description: "",
        imageUrl:
            "https://market-explorer-photos.s3.ap-southeast-2.amazonaws.com/placeholders/Market_all/%EC%A7%80%EB%8F%84_Musteat-%ED%83%90%EC%83%89_Musteat/%EA%B4%91%EC%9E%A5%EC%8B%9C%EC%9E%A5_%E1%84%8B%E1%85%B2%E1%86%A8%E1%84%92%E1%85%AC_ME197.png",
      ),
    ];
  }

  Widget _buildMustEatSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final mustTryItems = widget.market.mustTryItems.isNotEmpty
        ? widget.market.mustTryItems
        : _getDefaultMustTryItems();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 12)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Must eat ${widget.market.name.toLowerCase().replaceAll("시장", "").trim()}",
            style: textTheme.titleMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 16),
              fontWeight: FontWeight.w500,
              color: AppColors.mainText,
            ),
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: mustTryItems.take(3).map((item) {
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
                        fontSize: responsive.responsiveFontSize(mobileSize: 13),
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainText,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedHeader(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: responsive.responsivePadding(mobilePadding: 12),
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.market.name} NOW",
              style: textTheme.titleMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 16),
                fontWeight: FontWeight.w500,
                color: AppColors.mainText,
              ),
            ),
            SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
            // 필터 칩들
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["전체", "식사", "간식", "디저트", "음료"].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        right: responsive.responsivePadding(mobilePadding: 6),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.responsivePadding(
                          mobilePadding: 12,
                        ),
                        vertical: responsive.responsivePadding(
                          mobilePadding: 10,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        filter,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: responsive.responsiveFontSize(
                            mobileSize: 12,
                          ),
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedImageSlider(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    // 더미 이미지 데이터 (서버 연결 시 실제 데이터로 교체)
    final feedImages = [
      {"url": "https://placehold.co/323x367", "time": "n분 전"},
      {"url": "https://placehold.co/270x360", "time": "n분 전"},
    ];

    // ResponsivePadding과 동일한 마진 값 계산 (16, 24, 32)
    final horizontalMargin = responsive.responsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
    );

    return SizedBox(
      height: responsive.isMobile ? 367 : 400,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: feedImages.length,
        itemBuilder: (context, index) {
          final image = feedImages[index];

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? horizontalMargin : 0,
              right: responsive.responsivePadding(mobilePadding: 15),
            ),
            child: _buildFeedImage(responsive, image["url"]!, image["time"]!),
          );
        },
      ),
    );
  }

  Widget _buildFeedImage(
    ResponsiveHelper responsive,
    String imageUrl,
    String timeText,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFFF3EEF3));
              },
            ),
          ),
          Positioned(
            right: responsive.responsivePadding(mobilePadding: 10),
            bottom: responsive.responsivePadding(mobilePadding: 8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 10),
                vertical: responsive.responsivePadding(mobilePadding: 6),
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                timeText,
                style: TextStyle(
                  fontSize: responsive.responsiveFontSize(mobileSize: 12),
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 47,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.responsivePadding(mobilePadding: 12),
              vertical: responsive.responsivePadding(mobilePadding: 10),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: responsive.responsiveIconSize(mobileSize: 18),
                  color: AppColors.mainText,
                ),
                SizedBox(
                  width: responsive.responsivePadding(mobilePadding: 10),
                ),
                Text(
                  "떡볶이 메뉴 설명 보기",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.mainText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 8)),
          GestureDetector(
            onTap: () {
              context.push(
                '/map/market/${widget.market.id}/store-list',
                extra: {
                  'market': widget.market,
                  'menuName': "떡볶이", // TODO: 실제 선택된 메뉴명으로 변경
                },
              );
            },
            child: Container(
              width: double.infinity,
              height: 47,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 12),
                vertical: responsive.responsivePadding(mobilePadding: 10),
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store,
                    size: responsive.responsiveIconSize(mobileSize: 18),
                    color: AppColors.white,
                  ),
                  SizedBox(
                    width: responsive.responsivePadding(mobilePadding: 10),
                  ),
                  Text(
                    "${widget.market.name} 안 떡볶이 가게 보기",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowContent(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Must eat 섹션
          _buildMustEatSection(responsive, textTheme),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 피드 섹션 (제목과 필터)
          _buildFeedHeader(responsive, textTheme),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 피드 이미지 영역 (전체 너비)
          _buildFeedImageSlider(responsive, textTheme),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 버튼들
          _buildActionButtons(responsive, textTheme),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
        ],
      ),
    );
  }

  Widget _buildSavedContent(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          _buildSavedTitle(responsive, textTheme),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 저장된 가게 리스트
          _buildSavedStoreList(responsive, textTheme),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
        ],
      ),
    );
  }

  Widget _buildSavedTitle(ResponsiveHelper responsive, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 10)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "${widget.market.name} 내 저장 목록",
        style: textTheme.titleMedium?.copyWith(
          fontSize: responsive.responsiveFontSize(mobileSize: 16),
          fontWeight: FontWeight.w500,
          color: AppColors.mainText,
        ),
      ),
    );
  }

  Widget _buildSavedStoreList(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Column(
      children: _savedStores.map((store) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: responsive.responsivePadding(mobilePadding: 16),
          ),
          child: _buildSavedStoreCard(responsive, textTheme, store),
        );
      }).toList(),
    );
  }

  Widget _buildSavedStoreCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    StoreModel store,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 10)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역 (단일 이미지, 110x110)
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEF3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                store.imageUrls.isNotEmpty ? store.imageUrls[0] : "",
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFFF3EEF3));
                },
              ),
            ),
          ),
          SizedBox(width: responsive.responsivePadding(mobilePadding: 20)),
          // 정보 영역
          Expanded(
            child: SizedBox(
              height: 110, // 이미지 높이와 동일
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 가게명과 영업 상태
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: responsive.responsiveFontSize(
                                  mobileSize: 14,
                                ),
                                fontWeight: FontWeight.w500,
                                color: AppColors.mainText,
                              ),
                            ),
                            SizedBox(
                              height: responsive.responsivePadding(
                                mobilePadding: 2,
                              ),
                            ),
                            Text(
                              "${store.operatingHours ?? ""}\n${store.closedDays ?? ""}",
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: responsive.responsiveFontSize(
                                  mobileSize: 12,
                                ),
                                fontWeight: FontWeight.w400,
                                color: AppColors.inactiveText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: responsive.responsivePadding(mobilePadding: 8),
                      ),
                      // 영업 상태 표시
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(store.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  // 버튼들 (하단 정렬)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildLocationButtonForSaved(responsive, textTheme, store),
                      SizedBox(
                        width: responsive.responsivePadding(mobilePadding: 6),
                      ),
                      _buildSaveButtonForSaved(responsive, textTheme, store),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StoreStatus status) {
    switch (status) {
      case StoreStatus.open:
        return const Color(0xFF20CA83); // 청색
      case StoreStatus.closingSoon:
        return const Color(0xFFFFB800); // 황색
      case StoreStatus.closed:
        return AppColors.primary; // 적색
    }
  }

  Widget _buildLocationButtonForSaved(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    StoreModel store,
  ) {
    return GestureDetector(
      onTap: () {
        _moveToStoreLocation(store);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 10),
          vertical: responsive.responsivePadding(mobilePadding: 8),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: responsive.responsiveIconSize(mobileSize: 16),
              color: const Color(0xFF333333),
            ),
            SizedBox(width: responsive.responsivePadding(mobilePadding: 6)),
            Text(
              "위치 보기",
              style: textTheme.bodySmall?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 12),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButtonForSaved(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    StoreModel store,
  ) {
    // 저장 해제된 경우 회색 배경으로 표시
    final isSaved = store.isSaved;

    return GestureDetector(
      onTap: () {
        // 저장 해제 (리스트에서 바로 삭제하지 않음, 페이지를 나갔다 들어와야 삭제됨)
        setState(() {
          final index = _savedStores.indexWhere((s) => s.id == store.id);
          if (index != -1) {
            _savedStores[index] = StoreModel(
              id: store.id,
              name: store.name,
              imageUrls: store.imageUrls,
              address: store.address,
              status: store.status,
              isSaved: !store.isSaved, // 저장 상태 토글
              operatingHours: store.operatingHours,
              closedDays: store.closedDays,
            );
          }
        });
      },
      child: Container(
        height: 32,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 10),
          vertical: responsive.responsivePadding(mobilePadding: 8),
        ),
        decoration: BoxDecoration(
          color: isSaved
              ? const Color(0xFFFD312E) // 저장된 상태는 빨간색
              : const Color(0xFFF3F3F3), // 저장 해제된 상태는 회색
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          size: responsive.responsiveIconSize(mobileSize: 16),
          color: isSaved ? AppColors.white : const Color(0xFF333333),
        ),
      ),
    );
  }
}
