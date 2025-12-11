// lib/features/map/widgets/feed_image_slider.dart

import "package:flutter/material.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/utils/time_utils.dart";
import "../../../core/utils/image_utils.dart";
import "../../../data/repositories/api_repository.dart";
import "../../../data/services/market_photo_service.dart";

/// 피드 이미지 슬라이더 위젯
class FeedImageSlider extends StatefulWidget {
  final String marketId;
  final String selectedFilter;

  const FeedImageSlider({
    super.key,
    required this.marketId,
    required this.selectedFilter,
  });

  @override
  State<FeedImageSlider> createState() => _FeedImageSliderState();
}

class _FeedImageSliderState extends State<FeedImageSlider> {
  final _apiRepository = ApiRepository();
  List<MarketPhoto> _photos = [];
  bool _isLoading = true;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void didUpdateWidget(FeedImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter ||
        oldWidget.marketId != widget.marketId) {
      _loadPhotos();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiRepository.marketPhotoService.getMarketRecentPhotos(
        marketId: widget.marketId,
        category: widget.selectedFilter,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _photos = response.photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("사진 로드 실패: $e");
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

    // ResponsivePadding과 동일한 마진 값 계산 (16, 24, 32)
    final horizontalMargin = responsive.responsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
    );

    if (_isLoading) {
      return SizedBox(
        height: responsive.isMobile ? 367 : 400,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_photos.isEmpty) {
      return SizedBox(
        height: responsive.isMobile ? 367 : 400,
        child: Center(
          child: Text(
            "사진이 없습니다",
            style: TextStyle(
              fontSize: responsive.responsiveFontSize(mobileSize: 14),
              color: AppColors.subText,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: responsive.isMobile ? 367 : 400,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          final timeText = TimeUtils.formatTimeAgo(photo.takenAt);

          // s3_key를 CDN URL로 변환 (성능 최적화)
          final imageUrl = ImageUtils.s3KeyToCdnUrl(
            photo.thumbnailS3Key ?? photo.s3Key,
          );

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? horizontalMargin : 0,
              right: responsive.responsivePadding(mobilePadding: 15),
            ),
            child: _FeedImage(
              imageUrl: imageUrl,
              timeText: timeText,
            ),
          );
        },
      ),
    );
  }
}

class _FeedImage extends StatelessWidget {
  final String imageUrl;
  final String timeText;

  const _FeedImage({
    required this.imageUrl,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFFF3EEF3));
              },
            ),
          ),
          Positioned(
            right: responsive.responsivePadding(mobilePadding: 10),
            bottom: responsive.responsivePadding(mobilePadding: 8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 10),
                vertical: responsive.responsivePadding(mobilePadding: 6),
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                timeText,
                style: TextStyle(
                  fontSize: responsive.responsiveFontSize(mobileSize: 12),
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

