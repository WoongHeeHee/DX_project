// lib/features/report/report_store_select_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/loading_overlay.dart";
import "../map/models/store_model.dart";

class ReportStoreSelectScreen extends StatefulWidget {
  final XFile image;
  final double latitude;
  final double longitude;

  const ReportStoreSelectScreen({
    super.key,
    required this.image,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ReportStoreSelectScreen> createState() => _ReportStoreSelectScreenState();
}

class _ReportStoreSelectScreenState extends State<ReportStoreSelectScreen> {
  // final _apiRepository = ApiRepository(); // TODO: 실제 API 호출 시 사용
  List<StoreModel> _nearbyStores = [];
  String? _selectedStoreId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyStores();
  }

  Future<void> _loadNearbyStores() async {
    try {
      // 주변 가게 조회 (반경 5m 내)
      // TODO: 실제 API 호출 구현
      // final stores = await _apiRepository.shopService.getNearbyShops(
      //   lat: widget.latitude,
      //   lng: widget.longitude,
      //   radius: 5.0,
      // );
      
      // 임시 더미 데이터
      setState(() {
        _nearbyStores = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("주변 가게를 불러오는데 실패했습니다: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("가게를 선택해주세요"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: 실제 제보 완료 API 호출 구현
      // 1. 사진 업로드 (photo-init -> S3 업로드 -> photo-complete)
      // 2. 제보 완료 (report-complete)
      
      if (mounted) {
        context.go('/report/complete');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("제보에 실패했습니다: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: ResponsivePadding(
            mobilePadding: 16,
            tabletPadding: 24,
            desktopPadding: 32,
            child: Column(
              children: [
                // 상단 제목
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                      color: AppColors.mainText,
                    ),
                    Expanded(
                      child: Text(
                        "가게 선택",
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: responsive.responsiveFontSize(mobileSize: 20),
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
                SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
                // 안내 문구
                Text(
                  "촬영한 위치 주변의 가게를 선택해주세요",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 14),
                    color: AppColors.subText,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
                // 가게 리스트
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _nearbyStores.isEmpty
                          ? Center(
                              child: Text(
                                "주변에 가게가 없습니다.\n다른 위치에서 다시 시도해주세요.",
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: responsive.responsiveFontSize(mobileSize: 14),
                                  color: AppColors.subText,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _nearbyStores.length,
                              itemBuilder: (context, index) {
                                final store = _nearbyStores[index];
                                final isSelected = _selectedStoreId == store.id;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedStoreId = store.id;
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      bottom: responsive.responsivePadding(mobilePadding: 12),
                                    ),
                                    padding: EdgeInsets.all(
                                      responsive.responsivePadding(mobilePadding: 12),
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.1)
                                          : AppColors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.lightGrey,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        // 가게 이미지
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: AppColors.imagePlaceholder,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: store.imageUrls.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Image.network(
                                                    store.imageUrls.first,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.store,
                                                  color: AppColors.subText,
                                                ),
                                        ),
                                        SizedBox(
                                          width: responsive.responsivePadding(mobilePadding: 12),
                                        ),
                                        // 가게 정보
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                store.name,
                                                style: textTheme.titleMedium?.copyWith(
                                                  fontSize: responsive.responsiveFontSize(mobileSize: 16),
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.mainText,
                                                ),
                                              ),
                                              Text(
                                                store.address,
                                                style: textTheme.bodySmall?.copyWith(
                                                  fontSize: responsive.responsiveFontSize(mobileSize: 12),
                                                  color: AppColors.subText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // 선택 표시
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                // 선택 완료 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedStoreId == null ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.responsivePadding(mobilePadding: 16),
                      ),
                    ),
                    child: Text(
                      "선택 완료",
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: responsive.responsiveFontSize(mobileSize: 16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

