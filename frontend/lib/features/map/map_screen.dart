// lib/features/map/map_screen.dart

import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../data/repositories/api_repository.dart";
import "../../data/services/user_service.dart";
import "../../data/models/market_models.dart";
import "../home/models/market_model.dart";
import "../search/search_screen.dart";
import "market_map_detail_screen.dart";

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
    MapMarketData(
      id: "1",
      name: "광장시장",
      address: "주소가 들어갈 자리\n야호야호",
      imageUrl: "https://placehold.co/319x241",
      isOpen: true,
      pinPosition: const Offset(0.4, 0.3), // 지도 상대 위치
      keywords: ["야호야호", "키워드가 들어갈 자리", "여기는 조금 더 긴 키워드가 들어가도"],
    ),
    MapMarketData(
      id: "2",
      name: "망원시장",
      address: "서울특별시 마포구 망원동",
      imageUrl: "https://placehold.co/319x241",
      isOpen: false,
      pinPosition: const Offset(0.6, 0.3),
      keywords: ["키워드1", "키워드2"],
    ),
    MapMarketData(
      id: "3",
      name: "통인시장",
      address: "서울특별시 종로구 통인동",
      imageUrl: "https://placehold.co/319x241",
      isOpen: true,
      pinPosition: const Offset(0.3, 0.6),
      keywords: ["키워드1", "키워드2"],
    ),
    MapMarketData(
      id: "4",
      name: "서울풍물시장",
      address: "서울특별시 종로구",
      imageUrl: "https://placehold.co/319x241",
      isOpen: true,
      pinPosition: const Offset(0.7, 0.5),
      keywords: ["키워드1", "키워드2"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  Future<void> _loadMarkets() async {
    try {
      final locale = await _apiRepository.userService.getLocale();
      final markets = await _apiRepository.marketService.getMarkets();
      
      // 시장 상태 조회
      final marketsWithStatus = <MapMarketData>[];
      for (final market in markets) {
        try {
          final status = await _apiRepository.marketService.getMarketStatus(
            market.id,
            locale: locale,
          );
          
          // 시장 정보 조회 (주소 등)
          final marketInfo = await _apiRepository.marketService.getMarketInfo(market.id);
          
          marketsWithStatus.add(MapMarketData(
            id: market.id,
            name: market.getNameByLocale(locale),
            address: marketInfo.getAddressByLocale(locale) ?? '',
            imageUrl: market.silhouetteUrl ?? 'https://placehold.co/319x241',
            isOpen: status.status == 'green' || status.status == 'yellow',
            pinPosition: _calculatePinPosition(marketsWithStatus.length),
            keywords: [], // TODO: 키워드 추가 필요
          ));
        } catch (e) {
          debugPrint("시장 상태 조회 실패: $e");
          // 에러가 발생해도 기본 정보로 추가
          marketsWithStatus.add(MapMarketData(
            id: market.id,
            name: market.getNameByLocale(locale),
            address: '',
            imageUrl: market.silhouetteUrl ?? 'https://placehold.co/319x241',
            isOpen: true,
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
    );
  }

  Widget _buildSearchBar(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchScreen(),
            ),
          );
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
            // 지도 배너 이미지
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.imagePlaceholder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _markets[_currentCardIndex].imageUrl,
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
                market.isOpen,
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
    bool isOpen,
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
            color: isOpen ? const Color(0xFF20CA83) : AppColors.inactiveText,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isOpen ? const Color(0xFF20CA83) : AppColors.inactiveText)
                          .withOpacity(0.5),
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
    );
  }

  Widget _buildMarketCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MapMarketData market,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        // 카드 클릭 시 지도 상세 페이지로 이동
        final marketModel = _convertToMarketModel(market);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketMapDetailScreen(market: marketModel),
          ),
        );
      },
      child: Container(
        width: responsive.isMobile ? 343 : 400,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 12),
          vertical: responsive.responsivePadding(mobilePadding: 20),
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
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
                        color: market.isOpen
                            ? const Color(0xFF20CA83)
                            : AppColors.inactiveText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: responsive.responsivePadding(mobilePadding: 4)),
                    Text(
                      market.isOpen ? "영업 중" : "휴무일",
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
      operatingHours: data.isOpen ? "영업 중" : "휴무일",
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
  final bool isOpen; // true: 영업 중 (청색), false: 휴무일 (적색)
  final Offset pinPosition; // 지도 상의 핀 위치 (0.0 ~ 1.0)
  final List<String> keywords;

  MapMarketData({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.isOpen,
    required this.pinPosition,
    required this.keywords,
  });
}

