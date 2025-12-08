// lib/features/map/store_list_screen.dart

import "dart:async";
import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/kakao_map_widget.dart";
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

  // 스냅 포인트: 최소, 중간, 최대
  static const double _minSize = 0.1; // 인디케이터만 보일 정도
  static const double _midSize = 0.4; // 디폴트: 화면의 2/5
  static const double _maxSize = 0.95; // 거의 전체 화면

  // 더미 가게 데이터 (서버 연결 시 실제 데이터로 교체)
  final List<StoreModel> _stores = [
    StoreModel(
      id: "1",
      name: "가게명1",
      imageUrls: [
        "https://placehold.co/179x110",
        "https://placehold.co/179x110",
        "https://placehold.co/179x110",
      ],
      address: "서울특별시 마포구 망원동",
      status: StoreStatus.open,
      isSaved: false,
    ),
    StoreModel(
      id: "2",
      name: "가게명2",
      imageUrls: [
        "https://placehold.co/179x110",
        "https://placehold.co/179x110",
      ],
      address: "서울특별시 마포구 망원동",
      status: StoreStatus.closingSoon,
      isSaved: true,
    ),
    StoreModel(
      id: "3",
      name: "가게명3",
      imageUrls: [
        "https://placehold.co/179x110",
      ],
      address: "서울특별시 마포구 망원동",
      status: StoreStatus.closed,
      isSaved: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _draggableController = DraggableScrollableController();
    _draggableController.addListener(_onDragUpdate);
    _lastSize = _midSize;

    // 각 가게의 이미지 인덱스 초기화
    for (final store in _stores) {
      _storeImageIndices[store.id] = 0;
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // 지도 (전체 화면)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: KakaoMapWidget(
              address: widget.market.address,
              placeName: widget.market.name,
              height: screenHeight,
            ),
          ),
          // 뒤로가기 버튼
          _buildBackButton(responsive),
          // 드래그 가능한 바텀시트
          DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: _midSize,
            minChildSize: _minSize,
            maxChildSize: _maxSize,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    _buildIndicator(),
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
    return SingleChildScrollView(
      controller: scrollController,
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
                _buildStoreList(responsive, textTheme),
                SizedBox(
                  height: responsive.responsivePadding(mobilePadding: 16),
                ),
              ],
            ),
          ),
        ],
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
      children: _stores.map((store) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: responsive.responsivePadding(mobilePadding: 16),
          ),
          child: _buildStoreCard(responsive, textTheme, store),
        );
      }).toList(),
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
          // 이미지 영역
          _buildStoreImage(responsive, store),
          SizedBox(
            width: responsive.responsivePadding(mobilePadding: 20),
          ),
          // 정보 영역
          Expanded(
            child: SizedBox(
              height: 110, // 이미지 높이와 동일
              child: _buildStoreInfo(responsive, textTheme, store),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreImage(
    ResponsiveHelper responsive,
    StoreModel store,
  ) {
    // 최대 3개의 이미지만 표시
    final imagesToShow = store.imageUrls.take(3).toList();
    final currentIndex = _storeImageIndices[store.id] ?? 0;

    return Container(
      width: 179,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          // 이미지 슬라이더
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imagesToShow.length > 1
                ? PageView.builder(
                    controller: PageController(initialPage: currentIndex),
                    onPageChanged: (index) {
                      setState(() {
                        _storeImageIndices[store.id] = index;
                      });
                    },
                    itemCount: imagesToShow.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        imagesToShow[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: const Color(0xFFF3EEF3));
                        },
                      );
                    },
                  )
                : Image.network(
                    imagesToShow.isNotEmpty ? imagesToShow[0] : "",
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: const Color(0xFFF3EEF3));
                    },
                  ),
          ),
          // 인디케이터
          if (imagesToShow.length > 1)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: 179,
                height: 23,
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isActive = index < imagesToShow.length;
                    final isCurrent = index == currentIndex;
                    return Container(
                      width: isCurrent ? 14 : 6,
                      height: 6,
                      margin: EdgeInsets.only(
                        right: index < 2 ? 6 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isCurrent
                                ? AppColors.mainText
                                : const Color(0xFFF2F2F3))
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
    StoreModel store,
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
                store.name,
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
            _buildLocationButton(responsive, textTheme),
            SizedBox(
              width: responsive.responsivePadding(mobilePadding: 6),
            ),
            _buildSaveButton(responsive, textTheme, store),
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
  ) {
    return Container(
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
    );
  }

  Widget _buildSaveButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    StoreModel store,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // 저장 상태 토글 (실제로는 서버에 저장 요청)
          final index = _stores.indexWhere((s) => s.id == store.id);
          if (index != -1) {
            _stores[index] = StoreModel(
              id: store.id,
              name: store.name,
              imageUrls: store.imageUrls,
              address: store.address,
              status: store.status,
              isSaved: !store.isSaved,
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
          color: store.isSaved
              ? AppColors.primary
              : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          store.isSaved ? Icons.bookmark : Icons.bookmark_border,
          size: responsive.responsiveIconSize(mobileSize: 16),
          color: store.isSaved
              ? AppColors.white
              : const Color(0xFF333333),
        ),
      ),
    );
  }
}

