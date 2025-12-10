// lib/features/home/food_detail_screen.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../core/widgets/drag_only_scroll_behavior.dart";
import "../../data/repositories/api_repository.dart";
import "../../data/models/menu_models.dart";
import "models/food_model.dart";

class FoodDetailScreen extends StatefulWidget {
  final FoodModel food;

  const FoodDetailScreen({
    super.key,
    required this.food,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final _apiRepository = ApiRepository();
  int currentImageIndex = 0;
  bool _isLoading = false;
  bool _isSaved = false;
  String _locale = 'ko';
  MenuItemDetailModel? _menuItemDetail;

  @override
  void initState() {
    super.initState();
    _loadFoodData();
  }

  Future<void> _loadFoodData() async {
    setState(() {
      _isLoading = true;
    });

    String locale = _locale;
    try {
      locale = await _apiRepository.userService.getLocale();
    } catch (e) {
      debugPrint("locale 조회 실패, 기본값 사용: $e");
    }

    try {
      // 음식 상세 정보 조회 (저장 여부 포함)
      final menuItemDetail = await _apiRepository.menuService.getMenuItem(widget.food.id);
      
      if (mounted) {
        setState(() {
          _locale = locale;
          _menuItemDetail = menuItemDetail;
          _isSaved = menuItemDetail.isSaved;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("음식 데이터 로드 실패: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    final targetId = _menuItemDetail?.id ?? widget.food.id;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSaved) {
        await _apiRepository.menuService.unsaveMenuItem(targetId);
      } else {
        await _apiRepository.menuService.saveMenuItem(targetId);
      }
      
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
          _isLoading = false;
          if (_menuItemDetail != null) {
            _menuItemDetail = MenuItemDetailModel(
              id: _menuItemDetail!.id,
              name: _menuItemDetail!.name,
              nameEn: _menuItemDetail!.nameEn,
              nameZh: _menuItemDetail!.nameZh,
              nameJa: _menuItemDetail!.nameJa,
              description: _menuItemDetail!.description,
              descriptionEn: _menuItemDetail!.descriptionEn,
              descriptionZh: _menuItemDetail!.descriptionZh,
              descriptionJa: _menuItemDetail!.descriptionJa,
              similarFood: _menuItemDetail!.similarFood,
              similarFoodEn: _menuItemDetail!.similarFoodEn,
              similarFoodZh: _menuItemDetail!.similarFoodZh,
              similarFoodJa: _menuItemDetail!.similarFoodJa,
              repImageUrl: null, // rep_image_url 미사용
              price: _menuItemDetail!.price,
              contains: _menuItemDetail!.contains,
              containsEn: _menuItemDetail!.containsEn,
              containsZh: _menuItemDetail!.containsZh,
              containsJa: _menuItemDetail!.containsJa,
              mayContains: _menuItemDetail!.mayContains,
              mayContainsEn: _menuItemDetail!.mayContainsEn,
              mayContainsZh: _menuItemDetail!.mayContainsZh,
              mayContainsJa: _menuItemDetail!.mayContainsJa,
              category: _menuItemDetail!.category,
              spiceLevel: _menuItemDetail!.spiceLevel,
              createdAt: _menuItemDetail!.createdAt,
              isSaved: _isSaved,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("찜하기/찜 해제 실패: $e");
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
          child: ScrollConfiguration(
            behavior: DragOnlyScrollBehavior(),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackButton(responsive),
              _buildImageCarousel(responsive, textTheme),
              _buildFoodInfo(responsive, textTheme),
              _buildSpicinessSection(responsive, textTheme),
              _buildSimilarFoodsSection(responsive, textTheme),
              _buildAllergySection(responsive, textTheme),
            ],
              ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.mainText,
            ),
          ),
          IconButton(
            onPressed: _toggleSave,
            icon: Icon(
              _isSaved ? Icons.favorite : Icons.favorite_border,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: _isSaved ? AppColors.primary : AppColors.mainText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final images = _menuImages();
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
            child: ScrollConfiguration(
              behavior: DragOnlyScrollBehavior(),
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
                        return Container(
                          color: AppColors.imagePlaceholder,
                        );
                      },
                    ),
                  ),
                );
              },
              ),
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

  Widget _buildFoodInfo(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final name = _menuItemDetail?.getNameByLocale(_locale) ?? widget.food.name;
    final description =
        _menuItemDetail?.getDescriptionByLocale(_locale) ?? widget.food.description;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 16),
        vertical: responsive.responsivePadding(mobilePadding: 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            name,
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
            description,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 14),
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 5),
          ),
        ],
      ),
    );
  }

  Widget _buildSpicinessSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 16),
      ),
      padding: EdgeInsets.all(
        responsive.responsivePadding(mobilePadding: 16),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "맵기",
            style: textTheme.titleMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(
                mobileSize: 16,
                tabletSize: 18,
                desktopSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 맵기 바
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.imagePlaceholder,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: List.generate(5, (index) {
                final isFilled = index < widget.food.spiciness;
                double opacity = 0.0;
                if (isFilled) {
                  if (index < widget.food.spiciness - 2) {
                    opacity = 0.3;
                  } else if (index < widget.food.spiciness - 1) {
                    opacity = 0.7;
                  } else {
                    opacity = 1.0;
                  }
                }
                return Expanded(
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8.8),
          Text(
            widget.food.spicinessDescription,
            style: textTheme.bodySmall?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 12),
              color: AppColors.inactiveText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarFoodsSection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    if (_menuItemDetail != null) {
      final similar = _menuItemDetail!.getSimilarFoodByLocale(_locale);
      final hasSimilar = similar != null && similar.trim().isNotEmpty;
      if (!hasSimilar) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.all(
          responsive.responsivePadding(mobilePadding: 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "비슷한 음식",
              style: textTheme.titleMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(
                  mobileSize: 16,
                  tabletSize: 18,
                  desktopSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              similar,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 14),
                color: AppColors.mainText,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.food.similarFoods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(
        responsive.responsivePadding(mobilePadding: 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "비슷한 음식",
            style: textTheme.titleMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(
                mobileSize: 16,
                tabletSize: 18,
                desktopSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: widget.food.similarFoods.map((similarFood) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: similarFood == widget.food.similarFoods.last
                        ? 0
                        : responsive.responsivePadding(mobilePadding: 8),
                  ),
                  padding: EdgeInsets.all(
                    responsive.responsivePadding(mobilePadding: 10),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        similarFood.name,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: responsive.responsiveFontSize(mobileSize: 13),
                          fontWeight: FontWeight.w500,
                          color: AppColors.mainText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        similarFood.description,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: responsive.responsiveFontSize(mobileSize: 11),
                          color: AppColors.inactiveText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergySection(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    if (_menuItemDetail != null) {
      final contains = _menuItemDetail!.getContainsByLocale(_locale);
      final mayContains = _menuItemDetail!.getMayContainsByLocale(_locale);
      final hasContains = contains != null && contains.trim().isNotEmpty;
      final hasMayContains = mayContains != null && mayContains.trim().isNotEmpty;

      if (!hasContains && !hasMayContains) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.all(
          responsive.responsivePadding(mobilePadding: 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "알레르기 안내",
              style: textTheme.titleMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(
                  mobileSize: 16,
                  tabletSize: 18,
                  desktopSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (hasContains)
              _buildAllergyCard(
                responsive,
                textTheme,
                "Contain",
                contains,
              ),
            if (hasMayContains)
              _buildAllergyCard(
                responsive,
                textTheme,
                "May contain ",
                mayContains,
              ),
          ],
        ),
      );
    }

    if (widget.food.contains.isEmpty && widget.food.mayContain.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(
        responsive.responsivePadding(mobilePadding: 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "알레르기 안내",
            style: textTheme.titleMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(
                mobileSize: 16,
                tabletSize: 18,
                desktopSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // API에서 가져온 알레르기 정보 사용
          if (widget.food.contains.isNotEmpty)
            _buildAllergyCard(
              responsive,
              textTheme,
              "Contain",
              widget.food.contains.join(", "),
            ),
          if (widget.food.mayContain.isNotEmpty)
            _buildAllergyCard(
              responsive,
              textTheme,
              "May contain ",
              widget.food.mayContain.join(", "),
            ),
        ],
      ),
    );
  }

  Widget _buildAllergyCard(
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

  List<String> _menuImages() {
    // 이미지 경로는 locale과 무관하게 원본(ko) 이름 사용, rep_image_url 미사용
    final baseName = widget.food.baseName;
    final baseId = _menuItemDetail?.id ?? widget.food.id;
    return List.generate(
      3,
      (index) => _placeholderImage(baseName, baseId, variant: index + 1),
    );
  }

  String _placeholderImage(String name, String id, {int variant = 1}) {
    final encodedName = Uri.encodeComponent(name);
    final clampedVariant = variant < 1
        ? 1
        : (variant > 3 ? 3 : variant); // 파일명은 1~3 변형만 존재
    return "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/${encodedName}/${encodedName}${clampedVariant}_${id}.png";
  }

}

