// lib/features/map/widgets/saved_tab_content.dart

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "../../../core/widgets/responsive_helper.dart";
import "../../../core/widgets/responsive_padding.dart";
import "../../../core/theme/app_colors.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "../../../data/repositories/api_repository.dart";
import "../models/store_model.dart";

/// SAVED 탭 콘텐츠 위젯
class SavedTabContent extends StatefulWidget {
  final String marketName;
  final List<StoreModel> savedStores;
  final GoogleMapController? mapController;
  final ValueChanged<List<StoreModel>> onStoresChanged;

  const SavedTabContent({
    super.key,
    required this.marketName,
    required this.savedStores,
    required this.mapController,
    required this.onStoresChanged,
  });

  @override
  State<SavedTabContent> createState() => _SavedTabContentState();
}

class _SavedTabContentState extends State<SavedTabContent> {
  void _moveToStoreLocation(StoreModel store) {
    // 실제 가게 좌표를 사용하여 지도 이동
    if (store.lat != null && store.lng != null) {
      widget.mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(store.lat!, store.lng!),
          17.0,
        ),
      );
    }
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

  void _toggleSaveStatus(StoreModel store) async {
    final updatedStores = List<StoreModel>.from(widget.savedStores);
    final index = updatedStores.indexWhere((s) => s.id == store.id);
    if (index != -1) {
      try {
        if (store.isSaved) {
          await ApiRepository().shopService.unpinShop(store.id);
        } else {
          await ApiRepository().shopService.pinShop(store.id);
        }
        
        // 상태 업데이트
        updatedStores[index] = StoreModel(
          id: store.id,
          name: store.name,
          imageUrls: store.imageUrls,
          address: store.address,
          status: store.status,
          isSaved: !store.isSaved, // 저장 상태 토글
          operatingHours: store.operatingHours,
          closedDays: store.closedDays,
          lat: store.lat,
          lng: store.lng,
        );
        widget.onStoresChanged(updatedStores);
      } catch (e) {
        debugPrint("핀 상태 변경 실패: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          _SavedTitle(marketName: widget.marketName),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
          // 저장된 가게 리스트
          _SavedStoreList(
            savedStores: widget.savedStores,
            onMoveToLocation: _moveToStoreLocation,
            onToggleSave: _toggleSaveStatus,
            getStatusColor: _getStatusColor,
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
        ],
      ),
    );
  }
}

class _SavedTitle extends StatelessWidget {
  final String marketName;

  const _SavedTitle({required this.marketName});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 10)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$marketName 내 저장 목록",
        style: textTheme.titleMedium?.copyWith(
          fontSize: responsive.responsiveFontSize(mobileSize: 16),
          fontWeight: FontWeight.w500,
          color: AppColors.mainText,
        ),
      ),
    );
  }
}

class _SavedStoreList extends StatelessWidget {
  final List<StoreModel> savedStores;
  final Function(StoreModel) onMoveToLocation;
  final Function(StoreModel) onToggleSave;
  final Color Function(StoreStatus) getStatusColor;

  const _SavedStoreList({
    required this.savedStores,
    required this.onMoveToLocation,
    required this.onToggleSave,
    required this.getStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      children: savedStores.map((store) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: responsive.responsivePadding(mobilePadding: 16),
          ),
          child: _SavedStoreCard(
            store: store,
            onMoveToLocation: onMoveToLocation,
            onToggleSave: onToggleSave,
            getStatusColor: getStatusColor,
          ),
        );
      }).toList(),
    );
  }
}

class _SavedStoreCard extends StatefulWidget {
  final StoreModel store;
  final Function(StoreModel) onMoveToLocation;
  final Function(StoreModel) onToggleSave;
  final Color Function(StoreStatus) getStatusColor;

  const _SavedStoreCard({
    required this.store,
    required this.onMoveToLocation,
    required this.onToggleSave,
    required this.getStatusColor,
  });

  @override
  State<_SavedStoreCard> createState() => _SavedStoreCardState();
}

class _SavedStoreCardState extends State<_SavedStoreCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 10)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역 (최대 3개, 110x110)
          _buildStoreImage(responsive),
          SizedBox(width: responsive.responsivePadding(mobilePadding: 20)),
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
                              widget.store.name,
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
                              "${widget.store.operatingHours ?? ""}\n${widget.store.closedDays ?? ""}",
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
                          color: widget.getStatusColor(widget.store.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  // 버튼들 (하단 정렬)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _LocationButton(
                        onTap: () => widget.onMoveToLocation(widget.store),
                      ),
                      SizedBox(
                        width: responsive.responsivePadding(mobilePadding: 6),
                      ),
                      _SaveButton(
                        isSaved: widget.store.isSaved,
                        onTap: () => widget.onToggleSave(widget.store),
                      ),
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
  
  Widget _buildStoreImage(ResponsiveHelper responsive) {
    // 최대 3개의 이미지만 표시
    final imagesToShow = widget.store.imageUrls.take(3).toList();

    return Container(
      width: responsive.responsiveIconSize(mobileSize: 110),
      height: responsive.responsiveIconSize(mobileSize: 110),
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
                    controller: PageController(initialPage: _currentImageIndex),
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
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
                width: responsive.responsiveIconSize(mobileSize: 110),
                height: responsive.responsiveIconSize(mobileSize: 23),
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isActive = index < imagesToShow.length;
                    final isCurrent = index == _currentImageIndex;
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
}

class _LocationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LocationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
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
            SizedBox(width: responsive.responsivePadding(mobilePadding: 6)),
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
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;

  const _SaveButton({
    required this.isSaved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.responsivePadding(mobilePadding: 10),
          vertical: responsive.responsivePadding(mobilePadding: 8),
        ),
        decoration: BoxDecoration(
          color: isSaved
              ? const Color(0xFFFD312E) // 저장된 상태는 빨간색
              : const Color(0xFFF3F3F3), // 저장 해제된 상태는 회색
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
}

