// lib/features/map/market_map_detail_screen.dart

import "dart:async";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/google_map_widget.dart";
import "../../data/repositories/api_repository.dart";
import "../home/models/market_model.dart";
import "models/store_model.dart";
import "widgets/bottom_sheet_indicator.dart";
import "widgets/back_button.dart";
import "widgets/tab_selector.dart";
import "widgets/now_tab_content.dart";
import "widgets/saved_tab_content.dart";

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
          const MapBackButton(),
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
                    const BottomSheetIndicator(),
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

  Widget _buildBottomSheetContent(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    ScrollController scrollController,
  ) {
    return NotificationListener<ScrollNotification>(
      // 스크롤 이벤트를 소비해 상위(지도)로 전파되지 않도록 함
      onNotification: (notification) => true,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NOW/SAVED 탭
            TabSelector(
              isNowTab: _isNowTab,
              onTabChanged: (isNow) {
                setState(() {
                  _isNowTab = isNow;
                });
                if (isNow) {
                  _loadPhotoLocations();
                }
              },
            ),
            // 컨텐츠 영역
            _isNowTab
                ? NowTabContent(
                    market: widget.market,
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  )
                : SavedTabContent(
                    marketName: widget.market.name,
                    savedStores: _savedStores,
                    mapController: _mapController,
                    onStoresChanged: (stores) {
                      setState(() {
                        _savedStores = stores;
                      });
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
