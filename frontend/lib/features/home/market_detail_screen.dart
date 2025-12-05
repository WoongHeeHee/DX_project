// lib/features/home/market_detail_screen.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/kakao_map_widget.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../data/repositories/api_repository.dart";
import "../../data/models/market_models.dart" as api_models;
import "models/market_model.dart";

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
  
  // API로 가져온 데이터
  api_models.MarketInfoModel? _marketInfo;
  List<dynamic> _mustEatMenus = [];

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 시장 부가정보 조회
      final marketInfo = await _apiRepository.marketService.getMarketInfo(widget.market.id);
      
      // Must eat 메뉴 조회
      final mustEatMenus = await _apiRepository.marketService.getMarketMustEat(widget.market.id);
      
      if (mounted) {
        setState(() {
          _marketInfo = marketInfo;
          _mustEatMenus = mustEatMenus;
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
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
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
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: carouselHeight,
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
                      ? AppColors.mainText
                      : AppColors.imagePlaceholder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInfo(ResponsiveHelper responsive, TextTheme textTheme) {
    return Container(
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
            style: textTheme.titleLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(
                mobileSize: 22,
                tabletSize: 24,
                desktopSize: 26,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.market.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 14),
              fontWeight: FontWeight.w300,
              height: 1.5,
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
    return Container(
      padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Must try",
            style: textTheme.titleMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(
                mobileSize: 16,
                tabletSize: 18,
                desktopSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // API에서 가져온 Must eat 메뉴 사용
          if (_mustEatMenus.isEmpty)
            Text(
              "Must eat 메뉴가 없습니다.",
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.inactiveText,
              ),
            )
          else
            ..._mustEatMenus.map((item) {
              // TODO: Must eat 메뉴 모델 구조 확인 필요
              return _buildMustTryItem(
                responsive,
                textTheme,
                MustTryItem(
                  id: item['id'] ?? '',
                  name: item['name'] ?? '',
                  description: item['description'] ?? '',
                  imageUrl: item['image_url'] ?? 'https://placehold.co/117x77',
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMustTryItem(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MustTryItem item,
  ) {
    return Container(
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
          Container(
            width: responsive.isMobile ? 117 : 140,
            height: responsive.isMobile ? 77 : 92,
            decoration: BoxDecoration(
              color: AppColors.imagePlaceholder,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: AppColors.imagePlaceholder);
                },
              ),
            ),
          ),
          SizedBox(width: responsive.responsivePadding(mobilePadding: 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 13),
                    fontWeight: FontWeight.w500,
                    color: AppColors.mainText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 12),
                    color: AppColors.inactiveText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "오시는 길",
            style: textTheme.titleMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(
                mobileSize: 16,
                tabletSize: 18,
                desktopSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 카카오 지도 (광장시장인 경우에만 실제 지도 표시)
          widget.market.name == "광장시장"
              ? KakaoMapWidget(
                  address: widget.market.address,
                  placeName: widget.market.name,
                  height: responsive.isMobile ? 180 : 220,
                  latitude: 37.5700, // 광장시장 위도
                  longitude: 127.0015, // 광장시장 경도
                )
              : Container(
                  width: double.infinity,
                  height: responsive.isMobile ? 140 : 180,
                  decoration: BoxDecoration(
                    color: AppColors.imagePlaceholder,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.market.mapImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: AppColors.imagePlaceholder);
                      },
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          // 정보 카드들 (API에서 가져온 데이터 사용)
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
              _marketInfo!.getAddressByLocale('ko') ?? widget.market.address,
            ),
            _buildInfoCard(
              responsive,
              textTheme,
              "교통",
              _marketInfo!.getTransportByLocale('ko') ?? widget.market.transportation,
            ),
            _buildInfoCard(
              responsive,
              textTheme,
              "주차",
              _marketInfo!.getParkingByLocale('ko') ?? widget.market.parking,
            ),
            _buildInfoCard(
              responsive,
              textTheme,
              "화장실",
              _marketInfo!.getRestroomByLocale('ko') ?? widget.market.restroom,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 12),
              fontWeight: FontWeight.w500,
              color: AppColors.mainText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            style: textTheme.bodySmall?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 12),
              color: AppColors.inactiveText,
            ),
          ),
        ],
      ),
    );
  }
}
