// lib/features/map/map_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../core/widgets/drag_only_scroll_behavior.dart";
import "../../data/repositories/api_repository.dart";
import "../home/models/market_model.dart";
import "../../widgets/bottom_navigation_bar.dart";
import 'package:flutter/services.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final PageController _cardPageController = PageController(viewportFraction: 0.85);
  final _apiRepository = ApiRepository();
  int _currentCardIndex = 0;
  bool _isLoading = true;
  List<MapMarketData> _markets = [];

  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  Color _statusToColor(String status) {
    switch (status) {
      case 'green':
        return const Color(0xFF20CA83);
      case 'yellow':
        return const Color(0xFFFEC84B);
      case 'red':
        return const Color(0xFFF75C5C);
      default:
        return const Color(0xFF20CA83);
    }
  }

  Future<void> _loadMarkets() async {
    try {
      final locale = await _apiRepository.userService.getLocale();
      final markets = await _apiRepository.marketService.getMarkets();
      // 서울 4개 시장만 표시
      final allowedNames = {'광장시장', '망원시장', '통인시장', '서울풍물시장'};
      final filtered = markets.where((m) {
        final name = m.getNameByLocale(locale);
        return allowedNames.contains(name);
      }).toList();
      
      // 시장 상태 조회
      final marketsWithStatus = <MapMarketData>[];
      for (final market in filtered) {
        try {
          final status = await _apiRepository.marketService.getMarketStatus(
            market.id,
            locale: locale,
          );
          
          // 시장 정보 조회 (주소 등)
          final marketInfo = await _apiRepository.marketService.getMarketInfo(market.id);
          final statusColor = _statusToColor(status.status);
          
          marketsWithStatus.add(MapMarketData(
            id: market.id,
            name: market.getNameByLocale(locale),
            address: marketInfo.getAddressByLocale(locale) ?? '',
            imageUrl: market.silhouetteUrl ?? '',
            status: status.status,
            statusColor: statusColor,
            pinPosition: _calculatePinPosition(marketsWithStatus.length),
            keywords: [], // TODO: 키워드 추가 필요
          ));
        } catch (e) {
          debugPrint("시장 상태 조회 실패: $e");
          // 에러가 발생해도 기본 정보로 추가
          final statusColor = _statusToColor('green');
          marketsWithStatus.add(MapMarketData(
            id: market.id,
            name: market.getNameByLocale(locale),
            address: '',
            imageUrl: market.silhouetteUrl ?? '',
            status: 'green',
            statusColor: statusColor,
            pinPosition: _calculatePinPosition(marketsWithStatus.length),
            keywords: [],
          ));
        }
      }
      
      if (mounted) {
        setState(() {
          _markets = marketsWithStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("시장 목록 조회 실패: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Offset _calculatePinPosition(int index) {
    // 지도 상의 핀 위치 계산 (더미 위치)
    final positions = [
      const Offset(0.4, 0.3),
      const Offset(0.6, 0.3),
      const Offset(0.3, 0.6),
      const Offset(0.7, 0.5),
    ];
    return positions[index % positions.length];
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.white,
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
        body: SafeArea(
          child: Column(
            children: [
              // 검색창
              _buildSearchBar(responsive, textTheme),
              // 지도 배너와 핀
              Expanded(
                child: _buildMapSection(responsive, textTheme),
              ),
              // 휠 피커 카드 영역
              _buildWheelPickerCards(responsive, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: GestureDetector(
        onTap: () {
          context.push('/search');
        },
        child: Container(
          height: responsive.isMobile ? 56 : 64,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.responsivePadding(mobilePadding: 12),
            vertical: responsive.responsivePadding(mobilePadding: 8),
          ),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              SizedBox(
                width: responsive.responsiveIconSize(mobileSize: 24),
                height: responsive.responsiveIconSize(mobileSize: 24),
                child: Icon(
                  Icons.search,
                  size: responsive.responsiveIconSize(mobileSize: 16),
                  color: AppColors.subText,
                ),
              ),
              SizedBox(width: responsive.responsivePadding(mobilePadding: 8)),
              Expanded(
                child: Text(
                  "사진이나 텍스트로 궁금한 메뉴를 물어보세요",
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 12),
                    color: AppColors.subText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Container(
        height: responsive.isMobile ? 267 : 320,
        padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 12)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 지도 배너 이미지 (서울 실루엣)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.imagePlaceholder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/seoul_silhouette.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: AppColors.imagePlaceholder);
                  },
                ),
              ),
            ),
            // 핀들
            ..._markets.asMap().entries.map((entry) {
              final index = entry.key;
              final market = entry.value;
              return _buildPin(
                responsive,
                market.pinPosition,
                market.statusColor,
                market.name,
                index == _currentCardIndex,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPin(
    ResponsiveHelper responsive,
    Offset position,
    Color statusColor,
    String marketName,
    bool isSelected,
  ) {
    return Positioned(
      left: position.dx * (MediaQuery.of(context).size.width - 64), // 패딩 제외
      top: position.dy * (responsive.isMobile ? 243 : 296),
      child: GestureDetector(
        onTap: () {
          // 핀 클릭 시 해당 카드로 이동
          _cardPageController.animateToPage(
            _markets.indexWhere((m) => m.name == marketName),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          width: responsive.responsiveIconSize(mobileSize: 10),
          height: responsive.responsiveIconSize(mobileSize: 10),
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildWheelPickerCards(ResponsiveHelper responsive, TextTheme textTheme) {
    return SizedBox(
      height: responsive.isMobile ? 330 : 380,
      child: ScrollConfiguration(
        // 마우스 휠 스크롤 비활성화, 드래그만 허용
        behavior: DragOnlyScrollBehavior(),
        child: PageView.builder(
          controller: _cardPageController,
          onPageChanged: (index) {
            setState(() {
              _currentCardIndex = index;
            });
          },
          itemCount: _markets.length,
          itemBuilder: (context, index) {
            final market = _markets[index];
            final isSelected = index == _currentCardIndex;
            
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 16),
              ),
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.6,
                child: _buildMarketCard(responsive, textTheme, market, isSelected),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMarketCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MapMarketData market,
    bool isSelected,
  ) {
    Color _cardColor() {
      if (isSelected) return const Color(0xFFF8FAFC);
      if (market.status == 'red') return const Color(0xFFEAEAEA);
      return const Color(0xFFEBEBEB);
    }

    String _statusLabel() {
      switch (market.status) {
        case 'green':
          return "영업 중";
        case 'yellow':
          return "부분 영업";
        case 'red':
          return "휴무일";
        default:
          return "영업 중";
      }
    }

    return GestureDetector(
      onTap: () {
        // 카드 클릭 시 지도 상세 페이지로 이동
        final marketModel = _convertToMarketModel(market);
        context.push(
          '/map/market/${marketModel.id}/detail',
          extra: {'market': marketModel},
        );
      },
      child: Container(
        width: responsive.isMobile ? 343 : 400,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 12),
          vertical: responsive.responsivePadding(mobilePadding: 20),
        ),
        decoration: BoxDecoration(
          color: _cardColor(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시장 이름과 영업 상태
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  market.name,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 20),
                    fontWeight: FontWeight.w500,
                    color: AppColors.mainText,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: responsive.responsiveIconSize(mobileSize: 8),
                      height: responsive.responsiveIconSize(mobileSize: 8),
                      decoration: BoxDecoration(
                        color: market.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: responsive.responsivePadding(mobilePadding: 4)),
                    Text(
                      _statusLabel(),
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: responsive.responsiveFontSize(mobileSize: 11),
                        color: AppColors.subText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
            // 이미지와 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지
                Container(
                  width: responsive.isMobile ? 114 : 130,
                  height: responsive.isMobile ? 113 : 130,
                  decoration: BoxDecoration(
                    color: AppColors.imagePlaceholder,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      "https://placehold.co/114x113",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: AppColors.imagePlaceholder);
                      },
                    ),
                  ),
                ),
                SizedBox(width: responsive.responsivePadding(mobilePadding: 12)),
                // 키워드와 주소
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 키워드 칩들
                      Wrap(
                        spacing: responsive.responsivePadding(mobilePadding: 4),
                        runSpacing: responsive.responsivePadding(mobilePadding: 4),
                        children: market.keywords.map((keyword) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.responsivePadding(mobilePadding: 8),
                              vertical: responsive.responsivePadding(mobilePadding: 4),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              keyword,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: responsive.responsiveFontSize(mobileSize: 11),
                                color: AppColors.mainText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
                      // 주소
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.responsivePadding(mobilePadding: 10),
                          vertical: responsive.responsivePadding(mobilePadding: 8),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          market.address,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: responsive.responsiveFontSize(mobileSize: 11),
                            color: AppColors.subText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  MarketModel _convertToMarketModel(MapMarketData data) {
    return MarketModel(
      id: data.id,
      name: data.name,
      description: "${data.name}에 대한 설명입니다.",
      imageUrls: [data.imageUrl],
      mustTryItems: [],
      address: data.address,
      operatingHours: data.status == 'red' ? "휴무일" : "영업 중",
      transportation: "지하철, 버스 이용 가능",
      parking: "주차 가능",
      restroom: "화장실 있음",
      mapImageUrl: data.imageUrl,
    );
  }
}

// 지도 화면용 시장 데이터 모델
class MapMarketData {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final String status; // green, yellow, red
  final Color statusColor;
  final Offset pinPosition; // 지도 상의 핀 위치 (0.0 ~ 1.0)
  final List<String> keywords;

  MapMarketData({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.status,
    required this.statusColor,
    required this.pinPosition,
    required this.keywords,
  });
}

