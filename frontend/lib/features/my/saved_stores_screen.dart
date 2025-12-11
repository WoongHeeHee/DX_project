// lib/features/my/saved_stores_screen.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../map/models/store_model.dart";
import "../../data/repositories/api_repository.dart";
import "../../models/shop_model.dart";

class SavedStoresScreen extends StatefulWidget {
  const SavedStoresScreen({super.key});

  @override
  State<SavedStoresScreen> createState() => _SavedStoresScreenState();
}

class _SavedStoresScreenState extends State<SavedStoresScreen> {
  final _apiRepository = ApiRepository();
  String _selectedFilter = "전체";
  List<String> _marketFilters = ["전체"]; // 처음엔 전체만, 나중에 시장 칩이 추가될 수 있음
  List<StoreModel> _savedStores = []; // 저장된 가게 리스트
  Map<String, bool> _tempSavedStates = {}; // 임시 저장 상태 (화면을 나가기 전까지 유지)

  @override
  void initState() {
    super.initState();
    _loadSavedStores();
  }

  Future<void> _loadSavedStores() async {
    try {
      // API 호출하여 저장된 가게 리스트 가져오기
      final shops = await _apiRepository.shopService.getPinnedShops();
      
      // ShopModel을 StoreModel로 변환
      final stores = shops.map((shop) => _shopModelToStoreModel(shop)).toList();
      
      // 저장된 가게가 있으면 그 가게가 있는 시장을 _marketFilters에 추가
      final marketNames = <String>{};
      // TODO: 시장 정보는 ShopModel에 없으므로 별도로 조회해야 할 수 있음
      // 일단 "전체"만 사용
      
      setState(() {
        _savedStores = stores;
        _marketFilters = ["전체", ...marketNames];
      });
    } catch (e) {
      debugPrint("저장한 가게 로드 실패: $e");
    }
  }

  StoreModel _shopModelToStoreModel(ShopModel shop) {
    // status 문자열을 StoreStatus enum으로 변환
    StoreStatus storeStatus;
    switch (shop.status) {
      case "green":
        storeStatus = StoreStatus.open;
        break;
      case "yellow":
        storeStatus = StoreStatus.closingSoon;
        break;
      case "red":
        storeStatus = StoreStatus.closed;
        break;
      default:
        storeStatus = StoreStatus.open;
    }
    
    // operatingHours 포맷팅
    String? operatingHours;
    if (shop.openTime != null && shop.closeTime != null) {
      operatingHours = "${shop.openTime} - ${shop.closeTime}";
    }
    
    return StoreModel(
      id: shop.id,
      name: shop.name,
      imageUrls: shop.imageUrls ?? (shop.repImageUrl != null ? [shop.repImageUrl!] : []),
      address: shop.address ?? "",
      status: storeStatus,
      isSaved: true,
      operatingHours: operatingHours,
      closedDays: shop.closedDays,
      lat: shop.lat,
      lng: shop.lng,
    );
  }

  void _moveToStoreLocation(StoreModel store) {
    // TODO: 실제 가게 좌표를 사용하여 지도 이동
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(responsive, textTheme),
            // 필터 칩들
            _buildFilterChips(responsive, textTheme),
            // 저장된 가게 리스트
            Expanded(
              child: _buildStoreList(responsive, textTheme),
            ),
          ],
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

  Widget _buildFilterChips(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: responsive.responsivePadding(mobilePadding: 20),
        right: responsive.responsivePadding(mobilePadding: 20),
        top: responsive.responsivePadding(mobilePadding: 8),
        bottom: responsive.responsivePadding(mobilePadding: 8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _marketFilters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  // TODO: 필터에 따라 가게 리스트 필터링
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: responsive.responsivePadding(mobilePadding: 6),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.responsivePadding(mobilePadding: 12),
                    vertical: responsive.responsivePadding(mobilePadding: 10),
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
                      fontSize: responsive.responsiveFontSize(mobileSize: 12),
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.white : AppColors.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreList(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    if (_savedStores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "아직 맛있는 걸 못 찾으셨나요?",
              style: textTheme.bodyMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 16),
                fontWeight: FontWeight.w400,
                color: AppColors.inactiveText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 탐색 화면으로 이동
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    vertical:
                        responsive.responsivePadding(mobilePadding: 16) * 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  "찾으러 가기",
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 임시 저장 상태가 false인 항목은 필터링에서 제외 (화면을 나가기 전까지는 표시)
    final visibleStores =
        _savedStores.where((store) => _isStoreSaved(store.id)).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
        vertical: responsive.responsivePadding(mobilePadding: 8),
      ),
      child: Column(
        children: visibleStores.map((store) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: responsive.responsivePadding(mobilePadding: 16),
            ),
            child: _buildStoreCard(responsive, textTheme, store),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoreCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    StoreModel store,
  ) {
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
              child: store.imageUrls.isNotEmpty
                  ? Image.network(
                      store.imageUrls[0],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: const Color(0xFFF3EEF3));
                      },
                    )
                  : Container(color: const Color(0xFFF3EEF3)),
            ),
          ),
          SizedBox(
            width: responsive.responsivePadding(mobilePadding: 20),
          ),
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
                  // 위치 보기 버튼과 저장 버튼
                  Row(
                    children: [
                      _buildLocationButton(responsive, textTheme, store),
                      SizedBox(
                        width: responsive.responsivePadding(mobilePadding: 6),
                      ),
                      _buildSaveButton(responsive, textTheme, store),
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

  Widget _buildLocationButton(
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

  Future<void> _toggleSaveStore(String storeId) async {
    final isCurrentlySaved = _isStoreSaved(storeId);
    
    setState(() {
      // 임시 저장 상태 토글 (UI 즉시 반영)
      _tempSavedStates[storeId] = !isCurrentlySaved;
    });
    
    try {
      // API 호출
      if (!isCurrentlySaved) {
        await _apiRepository.shopService.pinShop(storeId);
      } else {
        await _apiRepository.shopService.unpinShop(storeId);
      }
    } catch (e) {
      // 실패 시 원래 상태로 복구
      setState(() {
        _tempSavedStates[storeId] = isCurrentlySaved;
      });
      debugPrint("가게 저장 토글 실패: $e");
    }
  }

  bool _isStoreSaved(String storeId) {
    // 임시 저장 상태가 있으면 그것을 사용, 없으면 기본값 true
    return _tempSavedStates[storeId] ?? true;
  }

  Widget _buildSaveButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    StoreModel store,
  ) {
    final isSaved = _isStoreSaved(store.id);

    return GestureDetector(
      onTap: () async {
        await _toggleSaveStore(store.id);
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
              : const Color(0xFFF3F3F3), // 저장 해제된 상태는 위치보기와 같은 회색
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
}

