// lib/features/map/store_list_screen.dart

import "dart:async";
import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/google_map_widget.dart";
import "../../data/repositories/api_repository.dart";
import "../../data/models/market_models.dart" as api_models;
import "../../data/services/api_service.dart";
import "../home/models/market_model.dart";
import "models/store_model.dart";


class StoreListScreen extends StatefulWidget {
  final MarketModel market;
  final String menuName; // 메뉴명

  const StoreListScreen({
    super.key,
    required this.market,
    required this.menuName,
  });

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  late DraggableScrollableController _draggableController;
  Timer? _snapTimer;
  double _lastSize = 0.4;
  final Map<String, int> _storeImageIndices = {}; // 각 가게의 현재 이미지 인덱스
  GoogleMapController? _mapController;
  Set<Marker> _storeMarkers = {};
  final _apiRepository = ApiRepository();
  
  List<api_models.ShopByMenuModel> _shops = [];
  bool _isLoading = true;
  Set<String> _pinnedShopIds = {}; // 핀한 가게 ID 집합
  double? _marketLat;
  double? _marketLng;
  String? _menuId; // 메뉴 ID (음식 사진 URL 생성용)

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
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 디버깅: 전달받은 메뉴 이름 확인
      debugPrint("[StoreListScreen] 가게 목록 로드 시작: marketId='${widget.market.id}', menuName='${widget.menuName}'");
      
      // 메뉴 이름으로 메뉴 ID 조회 (음식 사진 URL 생성용)
      try {
        final menus = await _apiRepository.menuService.getMenuItems();
        final matchedMenu = menus.firstWhere(
          (menu) => menu.name == widget.menuName,
          orElse: () => menus.first, // 매칭 실패 시 첫 번째 메뉴 사용
        );
        if (mounted) {
          setState(() {
            _menuId = matchedMenu.id;
          });
        }
        debugPrint("[StoreListScreen] 메뉴 ID 조회: menuName='${widget.menuName}', menuId='${_menuId}'");
      } catch (e) {
        debugPrint("[StoreListScreen] 메뉴 ID 조회 실패: $e");
        // 메뉴 ID 조회 실패해도 계속 진행
      }
      
      // 시장 정보를 API에서 가져와서 위치 정보 사용
      final marketInfo = await _apiRepository.marketService.getMarket(widget.market.id);
      final lat = marketInfo.lat;
      final lng = marketInfo.lng;
      
      if (mounted) {
        setState(() {
          _marketLat = lat;
          _marketLng = lng;
        });
      }

      final response = await _apiRepository.marketService.getShopsByMenu(
        marketId: widget.market.id,
        menuName: widget.menuName,
        lat: lat,
        lng: lng,
      );

      debugPrint("[StoreListScreen] API 응답: 가게 개수=${response.shops.length}");

      if (mounted) {
        setState(() {
          _shops = response.shops;
          _isLoading = false;
        });
        
        // 각 가게의 이미지 인덱스 초기화
        for (final shop in _shops) {
          _storeImageIndices[shop.id] = 0;
        }
        
        // 가게 마커 생성
        _updateStoreMarkers();
        
        // 지도 중심을 첫 번째 가게 위치로 이동 (가게가 있는 경우)
        if (_shops.isNotEmpty && _mapController != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(_shops[0].lat, _shops[0].lng),
                15.0,
              ),
            );
          });
        }
        
        // 가게 목록 로드 완료 후 핀한 가게 목록 로드
        _loadPinnedShops();
      }
    } catch (e, stackTrace) {
      debugPrint("가게 목록 로드 실패: $e");
      debugPrint("스택 트레이스: $stackTrace");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("가게 목록을 불러오는 중 오류가 발생했습니다: ${e.toString()}"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadPinnedShops() async {
    try {
      final pinnedShops = await _apiRepository.shopService.getPinnedShops(
        marketId: widget.market.id,
      );
      
      if (mounted) {
        setState(() {
          _pinnedShopIds = pinnedShops.map((shop) => shop.id).toSet();
        });
        debugPrint("핀한 가게 목록 로드 완료: ${_pinnedShopIds.length}개");
      }
    } catch (e) {
      debugPrint("핀한 가게 목록 로드 실패: $e");
      // 에러 발생 시 빈 Set으로 초기화 (핀한 가게가 없거나 조회 실패)
      if (mounted) {
        setState(() {
          _pinnedShopIds = {};
        });
      }
    }
  }

  void _updateStoreMarkers() {
    final markers = <Marker>{};
    for (final shop in _shops) {
      // 상태에 따른 마커 색상
      BitmapDescriptor icon;
      switch (shop.status) {
        case "green":
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          break;
        case "yellow":
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
          break;
        case "red":
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          break;
        default:
          icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }
      
      markers.add(
        Marker(
          markerId: MarkerId(shop.id),
          position: LatLng(shop.lat, shop.lng),
          icon: icon,
          infoWindow: InfoWindow(
            title: shop.name,
          ),
        ),
      );
    }
    
    setState(() {
      _storeMarkers = markers;
    });
  }

  void _moveToStoreLocation(api_models.ShopByMenuModel shop) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(shop.lat, shop.lng), 17.0),
    );
  }

  Future<void> _togglePin(api_models.ShopByMenuModel shop) async {
    final isPinned = _pinnedShopIds.contains(shop.id);
    
    // 즉시 UI 업데이트 (낙관적 업데이트)
    if (mounted) {
      setState(() {
        if (isPinned) {
          _pinnedShopIds.remove(shop.id);
        } else {
          _pinnedShopIds.add(shop.id);
        }
      });
      debugPrint("핀 상태 업데이트: ${shop.name} - ${isPinned ? '핀 해제' : '핀 추가'}");
    }
    
    try {
      if (isPinned) {
        await _apiRepository.shopService.unpinShop(shop.id);
        debugPrint("핀 해제 성공: ${shop.name}");
      } else {
        await _apiRepository.shopService.pinShop(shop.id);
        debugPrint("핀 추가 성공: ${shop.name}");
      }
    } on AuthException catch (e) {
      debugPrint("인증 실패: $e");
      // 실패 시 원래 상태로 복구
      if (mounted) {
        setState(() {
          if (isPinned) {
            _pinnedShopIds.add(shop.id);
          } else {
            _pinnedShopIds.remove(shop.id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("로그인이 필요합니다. 로그인 후 다시 시도해주세요."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("핀하기 실패: $e");
      // 실패 시 원래 상태로 복구
      if (mounted) {
        setState(() {
          if (isPinned) {
            _pinnedShopIds.add(shop.id);
          } else {
            _pinnedShopIds.remove(shop.id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("핀하기 실패: ${e.toString()}"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  StoreStatus _getStoreStatus(String status) {
    switch (status) {
      case "green":
        return StoreStatus.open;
      case "yellow":
        return StoreStatus.closingSoon;
      case "red":
        return StoreStatus.closed;
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

    if ((currentSize - _lastSize).abs() > 0.01) {
      _lastSize = currentSize;
      _snapTimer?.cancel();

      _snapTimer = Timer(const Duration(milliseconds: 50), () {
        if (!_draggableController.isAttached) return;

        final finalSize = _draggableController.size;
        final snapSize = _getNearestSnapPoint(finalSize);

        if ((finalSize - snapSize).abs() > 0.05) {
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
            latitude: _shops.isNotEmpty 
                ? _shops[0].lat 
                : (_marketLat ?? 37.5665),
            longitude: _shops.isNotEmpty 
                ? _shops[0].lng 
                : (_marketLng ?? 126.9780),
            address: widget.market.address,
            placeName: widget.market.name,
            height: MediaQuery.of(context).size.height,
            markers: _storeMarkers,
            onMapCreated: (controller) {
              _mapController = controller;
              // 가게가 로드되면 첫 번째 가게 위치로 이동
              if (_shops.isNotEmpty) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_shops[0].lat, _shops[0].lng),
                    15.0,
                  ),
                );
              }
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
                    _buildIndicator(responsive),
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
            width: responsive.responsiveIconSize(mobileSize: 40),
            height: responsive.responsiveIconSize(mobileSize: 40),
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

  Widget _buildIndicator(ResponsiveHelper responsive) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      width: responsive.responsiveIconSize(mobileSize: 40),
      height: responsive.responsiveIconSize(mobileSize: 4),
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
              ResponsivePadding(
                mobilePadding: 16,
                tabletPadding: 24,
                desktopPadding: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    _buildTitle(responsive, textTheme),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 16),
                    ),
                    // 가게 리스트
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_shops.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "가게가 없습니다",
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.subText,
                            ),
                          ),
                        ),
                      )
                    else
                      _buildStoreList(responsive, textTheme),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ResponsiveHelper responsive, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsive.responsivePadding(mobilePadding: 10),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "${widget.menuName} in ${widget.market.name}",
        style: textTheme.titleMedium?.copyWith(
          fontSize: responsive.responsiveFontSize(mobileSize: 16),
          fontWeight: FontWeight.w500,
          color: AppColors.mainText,
        ),
      ),
    );
  }

  Widget _buildStoreList(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Column(
      children: _shops.map((shop) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: responsive.responsivePadding(mobilePadding: 16),
          ),
          child: _buildStoreCard(responsive, textTheme, shop),
        );
      }).toList(),
    );
  }

  Widget _buildStoreCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    api_models.ShopByMenuModel shop,
  ) {
    final storeStatus = _getStoreStatus(shop.status);
    final isPinned = _pinnedShopIds.contains(shop.id);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        responsive.responsivePadding(mobilePadding: 10),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역
          _buildStoreImage(responsive, shop),
          SizedBox(
            width: responsive.responsivePadding(mobilePadding: 20),
          ),
          // 정보 영역
          Expanded(
            child: SizedBox(
              height: responsive.responsiveIconSize(mobileSize: 110), // 이미지 높이와 동일
              child: _buildStoreInfo(responsive, textTheme, shop, storeStatus, isPinned),
            ),
          ),
        ],
      ),
    );
  }

  /// 음식 사진 placeholder URL 생성
  String _getMenuImageUrl(String menuName, String? menuId, {int variant = 1}) {
    final encodedName = Uri.encodeComponent(menuName);
    final clamped = variant < 1 ? 1 : (variant > 3 ? 3 : variant);
    final id = menuId ?? "ME000"; // 메뉴 ID가 없으면 기본값 사용
    // 경로 규칙: placeholders/Menu_all/{name}/{name}{variant}_{id}.png
    return "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/$encodedName/$encodedName${clamped}_$id.png";
  }

  /// 음식 사진 placeholder URL 리스트 생성 (3개 variant)
  List<String> _getMenuImageUrls(String menuName, String? menuId) {
    return List.generate(3, (index) => _getMenuImageUrl(menuName, menuId, variant: index + 1));
  }

  Widget _buildStoreImage(
    ResponsiveHelper responsive,
    api_models.ShopByMenuModel shop,
  ) {
    // 음식 사진 URL 생성 (메뉴 이름과 ID 사용)
    final menuImageUrls = _getMenuImageUrls(widget.menuName, _menuId);
    final currentIndex = _storeImageIndices[shop.id] ?? 0;

    return Container(
      width: responsive.responsiveIconSize(mobileSize: 179),
      height: responsive.responsiveIconSize(mobileSize: 110),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          // 이미지 슬라이더
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: PageView.builder(
              controller: PageController(initialPage: currentIndex),
              onPageChanged: (index) {
                setState(() {
                  _storeImageIndices[shop.id] = index;
                });
              },
              itemCount: menuImageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  menuImageUrls[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: const Color(0xFFF3EEF3));
                  },
                );
              },
            ),
          ),
          // 인디케이터
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: responsive.responsiveIconSize(mobileSize: 179),
              height: responsive.responsiveIconSize(mobileSize: 23),
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isCurrent = index == currentIndex;
                  return Container(
                    width: isCurrent ? 14 : 6,
                    height: 6,
                    margin: EdgeInsets.only(
                      right: index < 2 ? 6 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.mainText
                          : const Color(0xFFF2F2F3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    api_models.ShopByMenuModel shop,
    StoreStatus status,
    bool isPinned,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 가게명과 영업 상태
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                shop.name,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 20),
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainText,
                ),
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
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        // 버튼들 (하단 정렬)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLocationButton(responsive, textTheme, shop),
            SizedBox(
              width: responsive.responsivePadding(mobilePadding: 6),
            ),
            _buildPinButton(responsive, textTheme, shop, isPinned),
          ],
        ),
      ],
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

  Widget _buildLocationButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    api_models.ShopByMenuModel shop,
  ) {
    return GestureDetector(
      onTap: () {
        _moveToStoreLocation(shop);
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
            SizedBox(
              width: responsive.responsivePadding(mobilePadding: 6),
            ),
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

  Widget _buildPinButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    api_models.ShopByMenuModel shop,
    bool isPinned,
  ) {
    return GestureDetector(
      onTap: () {
        _togglePin(shop);
      },
      child: Container(
        height: responsive.responsiveIconSize(mobileSize: 32),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 10),
          vertical: responsive.responsivePadding(mobilePadding: 8),
        ),
        decoration: BoxDecoration(
          color: isPinned
              ? AppColors.primary
              : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          isPinned ? Icons.bookmark : Icons.bookmark_border,
          size: responsive.responsiveIconSize(mobileSize: 16),
          color: isPinned
              ? AppColors.white
              : const Color(0xFF333333),
        ),
      ),
    );
  }
}
