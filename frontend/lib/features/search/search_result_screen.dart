// lib/features/search/search_result_screen.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../data/repositories/api_repository.dart";
import "models/search_result_model.dart";

class SearchResultScreen extends StatefulWidget {
  final SearchResultModel result;

  const SearchResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final _apiRepository = ApiRepository();
  bool _isFavorite = false; // 찜 버튼 상태
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedStatus();
  }

  Future<void> _loadSavedStatus() async {
    try {
      final menuItemDetail = await _apiRepository.menuService.getMenuItem(widget.result.id);
      if (mounted) {
        setState(() {
          _isFavorite = menuItemDetail.isSaved;
        });
      }
    } catch (e) {
      debugPrint("저장 상태 조회 실패: $e");
      // 에러가 발생해도 계속 진행 (기본값 false 사용)
    }
  }

  Future<void> _toggleSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        await _apiRepository.menuService.unsaveMenuItem(widget.result.id);
      } else {
        await _apiRepository.menuService.saveMenuItem(widget.result.id);
      }
      
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("찜하기/찜 해제 실패: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("저장에 실패했습니다. 다시 시도해주세요."),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// S3 버킷 메뉴 대표사진 URL 생성
  String _getMenuImageUrl() {
    final menuName = widget.result.menuName;
    final menuId = widget.result.id;
    // URL 형식: https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/${menu_items.name}/${menu_items.name}1_${menu_items.id}.png
    return "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/$menuName/${menuName}1_$menuId.png";
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.softGreyBackground,
        body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(
              responsive.responsivePadding(mobilePadding: 16),
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(responsive, textTheme),
                SizedBox(height: responsive.responsivePadding(mobilePadding: 8)),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ResponsivePadding(
                mobilePadding: 16,
                tabletPadding: 24,
                desktopPadding: 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                        const SizedBox(height: 12),
                    _buildTitle(responsive, textTheme),
                        const SizedBox(height: 16),
                    _buildImageSection(responsive, textTheme),
                        const SizedBox(height: 16),
                    _buildMenuNameAndFavorite(responsive, textTheme),
                    const SizedBox(height: 4),
                    _buildDescription(responsive, textTheme),
                        const SizedBox(height: 16),
                    _buildNearestMarketButton(responsive, textTheme),
                    SizedBox(
                          height: responsive.responsivePadding(mobilePadding: 16),
                    ),
                  ],
                    ),
                ),
              ),
            ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveHelper responsive, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.only(
        top: responsive.responsivePadding(mobilePadding: 6),
        left: responsive.responsivePadding(mobilePadding: 16),
        right: responsive.responsivePadding(mobilePadding: 16),
        bottom: responsive.responsivePadding(mobilePadding: 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.go('/search'),
            icon: Icon(
              Icons.arrow_back,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.mainText,
            ),
          ),
          const SizedBox(), // 오른쪽 정렬을 위한 공간
        ],
      ),
    );
  }

  Widget _buildTitle(ResponsiveHelper responsive, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: responsive.responsivePadding(mobilePadding: 8),
        bottom: responsive.responsivePadding(mobilePadding: 4),
      ),
      child: Text(
        "궁금한 시장 메뉴를 알려드릴게요",
        style: textTheme.titleLarge?.copyWith(
          fontSize: responsive.responsiveFontSize(
            mobileSize: 20,
            tabletSize: 22,
            desktopSize: 24,
          ),
          fontWeight: FontWeight.w500,
          height: 1.30,
          color: AppColors.mainText,
        ),
      ),
    );
  }

  Widget _buildImageSection(ResponsiveHelper responsive, TextTheme textTheme) {
    final imageHeight = responsive.isMobile ? 220.0 : 250.0;
    final imageUrl = _getMenuImageUrl();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF3), // 보라색 배경
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: double.infinity,
        height: imageHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFF3EEF3),
                child: Icon(
                  Icons.error,
                  size: responsive.responsiveIconSize(mobileSize: 40),
                  color: AppColors.subText,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuNameAndFavorite(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.result.menuName,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: responsive.responsiveFontSize(
                    mobileSize: 20,
                    tabletSize: 22,
                    desktopSize: 24,
                  ),
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleSave,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: responsive.responsiveIconSize(mobileSize: 18),
                    color: _isFavorite
                        ? AppColors.primary
                        : AppColors.mainText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ResponsiveHelper responsive, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.only(
        top: responsive.responsivePadding(mobilePadding: 4),
      ),
      child: Text(
        widget.result.description,
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          fontSize: responsive.responsiveFontSize(mobileSize: 14),
          fontWeight: FontWeight.w500,
          height: 1.50,
          color: AppColors.mainText,
        ),
      ),
    );
  }

  Widget _buildNearestMarketButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    // 서버에서 제공될 시장명과 메뉴명을 사용
    // 일단 더미 데이터로 표시
    final marketName = widget.result.nearestMarketName ?? "광장시장";
    final menuName = widget.result.menuName;

    return GestureDetector(
      onTap: () {
        // TODO: 서버에서 가장 가까운 시장 정보를 가져와서
        // 시장 상세 페이지로 이동하는 로직
        debugPrint("가장 가까운 시장: $marketName, 메뉴: $menuName");
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => MarketDetailScreen(market: market),
        //   ),
        // );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 16),
          vertical: responsive.responsivePadding(mobilePadding: 12),
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "가장 가까운 $marketName $menuName 가게 보러가기",
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 15),
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

