// lib/features/map/widgets/feed_image_slider.dart

import "package:flutter/material.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/utils/time_utils.dart";
import "../../../data/repositories/api_repository.dart";
import "../../../data/services/market_photo_service.dart";

/// 피드 이미지 슬라이더 위젯
class FeedImageSlider extends StatefulWidget {
  final String marketId;
  final String selectedFilter;
  final ValueChanged<MarketPhoto?>? onPhotoChanged;

  const FeedImageSlider({
    super.key,
    required this.marketId,
    required this.selectedFilter,
    this.onPhotoChanged,
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
      debugPrint("[FeedImageSlider] 사진 로드 시작: marketId=${widget.marketId}, filter=${widget.selectedFilter}");
      
      // 필터 값을 API 카테고리로 변환
      String? category;
      if (widget.selectedFilter != '전체') {
        final filterMap = {
          '식사': 'Meals',
          '간식': 'Snacks',
          '디저트': 'Sweets',
          '음료': 'Drink',
        };
        category = filterMap[widget.selectedFilter];
      }
      
      debugPrint("[FeedImageSlider] 변환된 category: $category");
      final response = await _apiRepository.marketPhotoService.getMarketRecentPhotos(
        marketId: widget.marketId,
        category: category,
        limit: 10,
      );

      debugPrint("[FeedImageSlider] API 응답: photos 개수 = ${response.photos.length}");
      if (response.photos.isNotEmpty) {
        for (int i = 0; i < response.photos.length && i < 3; i++) {
          final photo = response.photos[i];
          final s3Key = photo.thumbnailS3Key ?? photo.s3Key;
          final imageUrl = _s3KeyToCdnUrl(s3Key);
          debugPrint("[FeedImageSlider] Photo[$i]: id=${photo.id}, s3Key='${photo.s3Key}', thumbnailS3Key='${photo.thumbnailS3Key}', finalUrl='$imageUrl'");
        }
      }

      if (mounted) {
        setState(() {
          _photos = response.photos;
          _isLoading = false;
        });
        // 다음 프레임에서 콜백 호출 (위젯 렌더링 완료 후)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _photos.isNotEmpty && widget.onPhotoChanged != null) {
            widget.onPhotoChanged!(_photos[0]);
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint("사진 로드 실패: $e");
      debugPrint("스택 트레이스: $stackTrace");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// s3_key를 CDN URL로 변환 (explore_screen.dart의 _placeholderImage 방식 활용)
  String _s3KeyToCdnUrl(String? s3Key) {
    if (s3Key == null || s3Key.isEmpty) {
      return '';
    }
    
    final trimmed = s3Key.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return '';
    }
    
    // 이미 전체 URL인 경우 그대로 반환
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    
    // 앞의 슬래시 제거 (중복 방지)
    final cleanKey = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    
    // explore_screen.dart의 _placeholderImage 방식: 직접 CDN URL 구성
    return "https://dnzeuzpu74ulj.cloudfront.net/$cleanKey";
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
        onPageChanged: (index) {
          // 선택된 사진 변경 알림
          if (widget.onPhotoChanged != null && index < _photos.length) {
            widget.onPhotoChanged!(_photos[index]);
          }
        },
        itemBuilder: (context, index) {
          final photo = _photos[index];
          final timeText = TimeUtils.formatTimeAgo(photo.takenAt);

          // s3_key를 CDN URL로 변환 (explore_screen.dart의 _placeholderImage 방식 활용)
          final s3Key = photo.thumbnailS3Key ?? photo.s3Key;
          final imageUrl = _s3KeyToCdnUrl(s3Key);
          
          // 디버깅: s3_key 값 확인
          debugPrint("[FeedImageSlider] Photo[$index]: id=${photo.id}, thumbnailS3Key='${photo.thumbnailS3Key}', s3Key='${photo.s3Key}', finalUrl='$imageUrl'");
          
          // 빈 URL 체크
          if (imageUrl.isEmpty) {
            debugPrint("[FeedImageSlider] 경고: 빈 imageUrl (photo.id: ${photo.id}, thumbnailS3Key: '${photo.thumbnailS3Key}', s3Key: '${photo.s3Key}')");
          }

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? horizontalMargin : 0,
              right: responsive.responsivePadding(mobilePadding: 15),
            ),
            child: _FeedImage(
              imageUrl: imageUrl,
              timeText: timeText,
              photoId: photo.id,
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
  final String photoId;

  const _FeedImage({
    required this.imageUrl,
    required this.timeText,
    required this.photoId,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    // 빈 URL일 경우 placeholder 표시
    if (imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEF3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            color: AppColors.subText.withOpacity(0.5),
            size: 48,
          ),
        ),
      );
    }

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
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFFF3EEF3),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint("[FeedImageSlider] 이미지 로드 실패: photoId=$photoId, error=$error, URL=$imageUrl");
                return Container(
                  color: const Color(0xFFF3EEF3),
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      color: AppColors.subText.withOpacity(0.5),
                      size: 48,
                    ),
                  ),
                );
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

