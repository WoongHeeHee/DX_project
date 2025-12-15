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
      // 서울 5개 시장만 표시 (market_id 또는 이름으로 필터링)
      final allowedMarketIds = {'MA0001', 'MA0002', 'MA0003', 'MA0004', 'MA0000'}; // 광장시장, 망원시장, 통인시장, 서울풍물시장, DX시장
      final allowedNames = {'광장시장', '망원시장', '통인시장', '서울풍물시장', 'DX시장', 'DX 시장'}; // 이름 변형 고려
      final filtered = markets.where((m) {
        final name = m.getNameByLocale(locale);
        return allowedMarketIds.contains(m.id) || allowedNames.contains(name);
      }).toList();
      
      debugPrint("[_loadMarkets] 전체 시장 개수: ${markets.length}, 필터링된 시장 개수: ${filtered.length}");
      for (final market in filtered) {
        debugPrint("[_loadMarkets] 시장: id=${market.id}, name=${market.getNameByLocale(locale)}");
      }
      
      // 시장 상태 조회
      final marketsWithStatus = <MapMarketData>[];
      for (final market in filtered) {
        try {
          final status = await _apiRepository.marketService.getMarketStatus(
            market.id,
            locale: locale,
          );
          
          final statusColor = _statusToColor(status.status);
          
          // 시장 대표사진 생성
          final marketName = market.getNameByLocale(locale);
          final marketImageUrl = _marketPlaceholder(marketName, market.id, variant: 1);
          
          // 시장 정보 조회 (주소 등) - marketInfo에서 주소 가져오기
          String marketAddress = '';
          try {
            final marketInfo = await _apiRepository.marketService.getMarketInfo(market.id);
            final addressResult = marketInfo.getAddressByLocale(locale);
            marketAddress = addressResult?.trim() ?? '';
            debugPrint("[주소 조회] $marketName (${market.id}) - marketInfo 주소값: '$addressResult', 최종주소: '$marketAddress'");
            if (marketAddress.isEmpty) {
              debugPrint("[경고] 시장 주소가 비어있음: $marketName (market_id: ${market.id})");
              debugPrint("[경고] marketInfo 데이터 - address: '${marketInfo.address}', addressEn: '${marketInfo.addressEn}', locale: '$locale'");
            }
          } catch (e) {
            debugPrint("[에러] 시장 정보 조회 실패: $marketName (market_id: ${market.id}) - $e");
            // market_info가 없을 수 있으므로 에러를 무시하고 계속 진행
          }
          
          // 주소가 여전히 비어있으면 경고
          if (marketAddress.isEmpty) {
            debugPrint("[최종 경고] MapMarketData에 저장될 주소가 비어있음: $marketName (${market.id})");
          }
          
          // 키워드 조회 (top 2개만)
          List<String> topKeywords = [];
          try {
            final keywords = await _apiRepository.marketService.getMarketTopKeywords(market.id);
            topKeywords = keywords.take(2).map((k) => k.keyword).toList();
          } catch (e) {
            debugPrint("키워드 조회 실패: $e");
          }
          
          // 키워드가 2개 미만이면 시장별로 랜덤한 placeholder 키워드로 채우기
          if (topKeywords.length < 2) {
            final randomKeywords = _getRandomKeywords(market.id, 10); // 충분히 많은 키워드 가져오기
            for (final keyword in randomKeywords) {
              // 이미 있는 키워드와 중복되지 않는 것만 추가
              if (!topKeywords.contains(keyword)) {
                topKeywords.add(keyword);
                if (topKeywords.length >= 2) break;
              }
            }
          }
          
          marketsWithStatus.add(MapMarketData(
            id: market.id,
            name: marketName,
            address: marketAddress,
            imageUrl: marketImageUrl,
            status: status.status,
            statusColor: statusColor,
            pinPosition: _calculatePinPosition(marketsWithStatus.length),
            keywords: topKeywords,
          ));
        } catch (e) {
          debugPrint("시장 상태 조회 실패: ${market.getNameByLocale(locale)} (market_id: ${market.id}) - $e");
          // 에러가 발생해도 기본 정보로 추가
          final statusColor = _statusToColor('green');
          final marketName = market.getNameByLocale(locale);
          final marketImageUrl = _marketPlaceholder(marketName, market.id, variant: 1);
          
          // 에러 발생 시에도 주소 조회 시도 (marketInfo에서)
          String marketAddress = '';
          try {
            final marketInfo = await _apiRepository.marketService.getMarketInfo(market.id);
            final addressResult = marketInfo.getAddressByLocale(locale);
            marketAddress = addressResult?.trim() ?? '';
            debugPrint("[에러상황 주소 조회] $marketName (${market.id}) - 주소값: '$addressResult', 최종주소: '$marketAddress'");
          } catch (e2) {
            debugPrint("[에러] 에러 상황에서 주소 조회도 실패: $marketName (${market.id}) - $e2");
          }
          
          // 에러 발생 시에도 시장별로 랜덤한 placeholder 키워드 추가
          final placeholderKeywords = _getRandomKeywords(market.id, 2);
          
          marketsWithStatus.add(MapMarketData(
            id: market.id,
            name: marketName,
            address: marketAddress,
            imageUrl: marketImageUrl,
            status: 'green',
            statusColor: statusColor,
            pinPosition: _calculatePinPosition(marketsWithStatus.length),
            keywords: placeholderKeywords,
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
      const Offset(0.5, 0.7),
    ];
    return positions[index % positions.length];
  }

  String _toCdn(String url) {
    // S3 정규식 치환 (모든 리전 호환)
    final cdnUrl = url.replaceFirst(
      RegExp(r'https?:\/\/market-explorer-photos\.s3\.[^\/]+\.amazonaws\.com'),
      'https://dnzeuzpu74ulj.cloudfront.net',
    );

    // 상대 경로 처리 (/path 형태)
    if (cdnUrl.startsWith('/')) {
      return 'https://dnzeuzpu74ulj.cloudfront.net$cdnUrl';
    }

    return cdnUrl;
  }

  String _marketPlaceholder(String name, String id, {int variant = 1}) {
    final encodedName = Uri.encodeComponent(name);
    final clamped = variant < 1 ? 1 : (variant > 3 ? 3 : variant);
    return _toCdn(
        "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Market_all/%ED%83%90%EC%83%89_Discover+Sijang/${encodedName}${clamped}_${id}.png");
  }

  /// Placeholder 키워드 목록 반환 (키워드 집계가 없을 때 사용)
  List<String> _getPlaceholderKeywords() {
    return [
      "맛집 많음",
      "관광 명소",
      "로컬 맛집",
      "한적함",
      "인생샷",
      "아이 동반",
      "부모님 동반",
      "대중교통 편리",
      "주차 편리",
      "자전거 편리",
      "휠체어 접근",
      "유모차 편리",
      "친절함",
    ];
  }

  /// 시장 ID를 시드로 사용하여 시장별로 랜덤하게 키워드 선택
  List<String> _getRandomKeywords(String marketId, int count) {
    final allKeywords = _getPlaceholderKeywords();
    if (allKeywords.length <= count) {
      return allKeywords;
    }
    
    // 시장 ID를 시드로 사용하여 랜덤 선택
    final seed = marketId.hashCode;
    final random = (seed % 1000000) / 1000000.0; // 0.0 ~ 1.0 사이 값
    
    // 시드를 기반으로 키워드 섞기
    final shuffled = List<String>.from(allKeywords);
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = ((random * (i + 1)) * 1000) % (i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j.toInt()];
      shuffled[j.toInt()] = temp;
    }
    
    return shuffled.take(count).toList();
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
                color: const Color(0xFFFEFEFE), // #FEFEFE 배경색
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE8E8E9), // #e8e8e9 border 색상
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/seoul_silhouette.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: const Color(0xFFFEFEFE));
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
      height: responsive.isMobile ? 280 : 330,
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
          vertical: responsive.responsivePadding(mobilePadding: 12),
        ),
        decoration: BoxDecoration(
          color: _cardColor(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
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
            SizedBox(height: responsive.responsivePadding(mobilePadding: 12)),
            // 이미지와 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지
                Container(
                  width: responsive.isMobile ? 100 : 120,
                  height: responsive.isMobile ? 100 : 120,
                  decoration: BoxDecoration(
                    color: AppColors.imagePlaceholder,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      market.imageUrl,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 키워드 칩들 (Column으로 세로 배치)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: market.keywords.take(2).map((keyword) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: responsive.responsivePadding(mobilePadding: 3),
                            ),
                            child: Container(
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
                            ),
                          );
                        }).toList(),
                      ),
                      // 주소 표시 (비어있지 않으면 표시)
                      if (market.address.trim().isNotEmpty) ...[
                        SizedBox(height: responsive.responsivePadding(mobilePadding: 6)),
                        // 주소
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.responsivePadding(mobilePadding: 10),
                            vertical: responsive.responsivePadding(mobilePadding: 4),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        // 주소가 없을 때도 디버깅을 위해 빈 공간 추가하지 않음
                        SizedBox(height: responsive.responsivePadding(mobilePadding: 0)),
                      ],
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

