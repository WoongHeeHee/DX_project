// lib/features/map/market_map_detail_screen.dart

import "dart:async";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/google_map_widget.dart";
import "../../data/repositories/api_repository.dart";
import "../../data/models/market_models.dart" as api_models;
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
  Set<Marker> _marketMarkers = {}; // 시장 마커
  Set<Marker> _storeMarkers = {}; // 가게 마커 (넘버링 포함)
  api_models.MarketModel? _apiMarket; // API에서 가져온 시장 정보 (lat, lng 포함)

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
    _loadMarketData();
    _loadSavedStores();
    _loadPhotoLocations();
  }

  /// API에서 시장 정보 가져오기 (lat, lng 포함)
  Future<void> _loadMarketData() async {
    try {
      final markets = await _apiRepository.marketService.getMarkets();
      final market = markets.firstWhere(
        (m) => m.id == widget.market.id,
        orElse: () => markets.first,
      );
      if (mounted) {
        setState(() {
          _apiMarket = market;
        });
        // 시장 마커 생성
        _createMarketMarker();
        // 지도 위치 업데이트
        _updateMapPosition();
      }
    } catch (e) {
      debugPrint("시장 정보 로드 실패: $e");
    }
  }

  /// 시장 위치에 커스텀 핀 마커 생성
  Future<void> _createMarketMarker() async {
    if (_apiMarket == null || _apiMarket!.lat == null || _apiMarket!.lng == null) {
      return;
    }

    if (!mounted) return;

    // 일반 구글 핀 사용
    if (mounted) {
      setState(() {
        _marketMarkers = {
          Marker(
            markerId: const MarkerId('market'),
            position: LatLng(_apiMarket!.lat!, _apiMarket!.lng!),
            icon: BitmapDescriptor.defaultMarker,
          ),
        };
      });
    }
  }

  /// 시장 이름에 따른 축적 계산
  /// 망원시장: 1cm:100m -> zoom 16
  /// DX시장: 1cm:200m -> zoom 15
  double _calculateZoomLevel(String marketName) {
    if (marketName.contains("망원시장")) {
      return 16.0; // 1cm:100m에 해당하는 zoom level
    } else if (marketName.contains("DX") || marketName.contains("DX시장")) {
      return 15.0; // 1cm:200m에 해당하는 zoom level
    }
    // 기본값
    return 15.0;
  }

  /// 지도 위치 업데이트
  /// - 지도-시장화면(1): market의 lat, lng을 중앙으로
  /// - 지도-시장화면(2): 리스트에 가게가 있으면 1번 가게의 lat, lng을 중앙으로, 없으면 market의 lat, lng을 중앙으로
  /// - 지도-시장화면(3): 리스트에 가게가 있으면 1번 가게의 lat, lng을 중앙으로, 없으면 market의 lat, lng을 중앙으로
  void _updateMapPosition() {
    if (_mapController == null) return;

    LatLng? targetLatLng;
    double zoom = _calculateZoomLevel(widget.market.name);

    // 지도-시장화면(1): NOW 탭, 바텀시트 최소 -> market의 좌표 사용
    if (_isNowTab && _lastSize <= _minSize + 0.05) {
      if (_apiMarket != null && _apiMarket!.lat != null && _apiMarket!.lng != null) {
        targetLatLng = LatLng(_apiMarket!.lat!, _apiMarket!.lng!);
      }
    }
    // 지도-시장화면(2): NOW 탭, 바텀시트 열림 -> 리스트에 가게가 있으면 1번 가게, 없으면 market
    else if (_isNowTab) {
      // NOW 탭에서는 사진 마커를 표시하지만, 위치는 market 좌표 사용
      if (_apiMarket != null && _apiMarket!.lat != null && _apiMarket!.lng != null) {
        targetLatLng = LatLng(_apiMarket!.lat!, _apiMarket!.lng!);
      }
    }
    // 지도-시장화면(3): SAVED 탭 -> 리스트에 가게가 있으면 1번 가게, 없으면 market
    else {
      if (_savedStores.isNotEmpty) {
        final firstStore = _savedStores.first;
        if (firstStore.lat != null && firstStore.lng != null) {
          targetLatLng = LatLng(firstStore.lat!, firstStore.lng!);
        }
      }
      
      // 가게 리스트가 없으면 market의 좌표 사용
      if (targetLatLng == null && _apiMarket != null) {
        if (_apiMarket!.lat != null && _apiMarket!.lng != null) {
          targetLatLng = LatLng(_apiMarket!.lat!, _apiMarket!.lng!);
        }
      }
    }

    if (targetLatLng != null && _mapController != null) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(targetLatLng, zoom),
        );
      } catch (e) {
        debugPrint("[_updateMapPosition] 지도 위치 업데이트 실패: $e");
      }
    }
  }

  Future<void> _loadPhotoLocations() async {
    if (_isNowTab) {
      try {
        final response = await _apiRepository.marketPhotoService.getMarketPhotoLocations(
          marketId: widget.market.id,
          limit: 10,
        );
        
        // 일반 구글 핀 사용
        final markers = <Marker>{};
        for (var i = 0; i < response.locations.length; i++) {
          final location = response.locations[i];
          markers.add(
            Marker(
              markerId: MarkerId('photo_${location.photoId}'),
              position: LatLng(location.lat, location.lng),
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
        }
        
        if (mounted) {
          setState(() {
            _photoMarkers = markers;
          });
        }
      } catch (e) {
        debugPrint("사진 위치 로드 실패: $e");
      }
    } else {
      // SAVED 탭일 때는 사진 마커 제거
      if (mounted) {
        setState(() {
          _photoMarkers = {};
        });
      }
    }
  }

  Future<void> _loadSavedStores() async {
    try {
      debugPrint("[_loadSavedStores] 핀한 가게 목록 로드 시작: marketId='${widget.market.id}'");
      final pinnedShops = await _apiRepository.shopService.getPinnedShops(
        marketId: widget.market.id,
      );
      
      debugPrint("[_loadSavedStores] API 응답: 가게 개수=${pinnedShops.length}");
      for (var i = 0; i < pinnedShops.length; i++) {
        final shop = pinnedShops[i];
        debugPrint("[_loadSavedStores] 가게[$i]: id='${shop.id}', name='${shop.name}', market_id='${shop.marketId}'");
      }
      
      if (mounted) {
        setState(() {
          _savedStores = pinnedShops.map((shop) {
            // 영업시간 문자열 생성 (예: "9:00 - 19:00")
            String? operatingHours;
            if (shop.openTime != null && shop.closeTime != null) {
              operatingHours = "${shop.openTime} - ${shop.closeTime}";
            }
            
            // ShopModel을 StoreModel로 변환
            // 실시간 사진이 있으면 사용, 없으면 대표 이미지 사용
            List<String> imageUrls = shop.imageUrls ?? [];
            if (imageUrls.isEmpty && shop.repImageUrl != null) {
              imageUrls = [shop.repImageUrl!];
            }
            
            return StoreModel(
              id: shop.id,
              name: shop.name,
              imageUrls: imageUrls,
              address: shop.address ?? "",
              status: _convertStatusStringToEnum(shop.status ?? "red"),
              isSaved: true,
              operatingHours: operatingHours,
              closedDays: shop.closedDays,
              lat: shop.lat,
              lng: shop.lng,
            );
          }).toList();
        });
        // 저장된 가게 목록이 업데이트되면 지도 위치 업데이트 (컨트롤러가 준비된 후)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _mapController != null) {
            _updateMapPosition();
          }
        });
        // 가게 마커 생성
        _createStoreMarkers();
      }
    } catch (e) {
      debugPrint("핀한 가게 목록 로드 실패: $e");
      if (mounted) {
        setState(() {
          _savedStores = [];
          _storeMarkers = {};
        });
      }
    }
  }

  /// 넘버링이 있는 가게 마커 생성
  Future<void> _createStoreMarkers() async {
    if (_savedStores.isEmpty || !mounted) {
      setState(() {
        _storeMarkers = {};
      });
      return;
    }

    // 일반 구글 핀 사용
    final markers = <Marker>{};
    for (var i = 0; i < _savedStores.length; i++) {
      final store = _savedStores[i];
      if (store.lat == null || store.lng == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId('store_${store.id}'),
          position: LatLng(store.lat!, store.lng!),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _storeMarkers = markers;
      });
    }
  }

  StoreStatus _convertStatusStringToEnum(String status) {
    switch (status) {
      case "green":
        return StoreStatus.open;
      case "yellow":
        return StoreStatus.closingSoon;
      case "red":
      default:
        return StoreStatus.closed;
    }
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
      
      // 바텀시트 크기가 변경되면 마커와 지도 위치 업데이트
      if (mounted) {
        setState(() {
          // 상태 업데이트로 지도 재빌드 (key 변경으로 인해)
        });
        // 지도 위치 업데이트
        Future.delayed(const Duration(milliseconds: 100), () {
          _updateMapPosition();
        });
      }

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

  /// 현재 화면에 맞는 마커 반환
  /// - 지도-시장화면(1): 시장 마커만 (NOW 탭, 바텀시트 최소)
  /// - 지도-시장화면(2): 사진 마커만 (NOW 탭, 바텀시트 열림)
  /// - 지도-시장화면(3): 가게 마커만 (SAVED 탭, 시장 마커 제외)
  Set<Marker> _getMarkersForCurrentScreen() {
    if (_isNowTab) {
      // NOW 탭: 시장 마커 + 사진 마커
      // 바텀시트가 최소일 때는 시장 마커만, 열려있을 때는 사진 마커만
      if (_lastSize <= _minSize + 0.05) {
        // 바텀시트가 최소일 때: 시장 마커만 (지도-시장화면(1))
        return _marketMarkers;
      } else {
        // 바텀시트가 열려있을 때: 사진 마커만 (지도-시장화면(2))
        return _photoMarkers;
      }
    } else {
      // SAVED 탭: 가게 마커만 (지도-시장화면(3), 시장 마커 제외)
      return _storeMarkers;
    }
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
          // key를 추가하여 마커나 위치 변경 시 지도가 다시 그려지도록 함
          GoogleMapWidget(
            key: ValueKey('${_isNowTab}_${_lastSize.toStringAsFixed(2)}_${_getMarkersForCurrentScreen().length}'),
            latitude: _apiMarket?.lat ?? 37.5665,
            longitude: _apiMarket?.lng ?? 126.9780,
            address: widget.market.address,
            placeName: widget.market.name,
            height: MediaQuery.of(context).size.height,
            markers: _getMarkersForCurrentScreen(),
            onMapCreated: (controller) {
              if (mounted) {
                setState(() {
                  _mapController = controller;
                });
                // 지도 생성 후 위치 업데이트 (웹 환경에서 컨트롤러 초기화 완료 대기)
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && _mapController != null) {
                    _updateMapPosition();
                  }
                });
              }
            },
            zoom: _calculateZoomLevel(widget.market.name),
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
                } else {
                  // SAVED 탭으로 변경 시 가게 마커 생성
                  _createStoreMarkers();
                }
                // 탭 변경 시 지도 위치 업데이트
                Future.delayed(const Duration(milliseconds: 200), () {
                  _updateMapPosition();
                });
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
