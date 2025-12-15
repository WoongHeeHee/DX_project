import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../data/repositories/api_repository.dart";
import "../../models/shop_model.dart";

class ReportShopSelectScreen extends StatefulWidget {
  const ReportShopSelectScreen({super.key});

  @override
  State<ReportShopSelectScreen> createState() => _ReportShopSelectScreenState();
}

class _ReportShopSelectScreenState extends State<ReportShopSelectScreen> {
  String? _selectedShopId;
  List<ShopModel> _shops = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _apiRepository = ApiRepository();

  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadNearbyShops();
    }
  }

  Future<void> _loadNearbyShops() async {
    // extra에서 lat, lng 가져오기
    final state = GoRouterState.of(context);
    final extra = state.extra as Map<String, dynamic>?;
    if (extra == null || !extra.containsKey('lat') || !extra.containsKey('lng')) {
      setState(() {
        _isLoading = false;
        _errorMessage = '위치 정보가 없습니다.';
      });
      return;
    }

    final lat = extra['lat'] as double;
    final lng = extra['lng'] as double;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 가까운 가게 3개 조회 (반경 1000m 내)
      final shops = await _apiRepository.shopService.getNearbyShops(
        lat: lat,
        lng: lng,
        radiusMeters: 1000.0,
        limit: 3,
      );

      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '가게 정보를 불러오는데 실패했습니다: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ResponsivePadding(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 40),
                      ),
                      _buildTitle(textTheme, responsive),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 40),
                      ),
                      _buildShopOptions(responsive, textTheme),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomButton(context, responsive, textTheme),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(TextTheme textTheme, ResponsiveHelper responsive) {
    return Text(
      "촬영하신 음식의\n가게를 선택해주세요",
      style: textTheme.headlineLarge?.copyWith(
        fontSize: responsive.responsiveFontSize(mobileSize: 26),
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.mainText,
      ),
    );
  }

  Widget _buildShopOptions(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 40)),
          child: Column(
            children: [
              Text(
                _errorMessage!,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.inactiveText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: responsive.responsivePadding(mobilePadding: 16),
              ),
              ElevatedButton(
                onPressed: _loadNearbyShops,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_shops.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 40)),
          child: Text(
            '주변에 가게가 없습니다.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.inactiveText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: _shops.map((shop) {
        final isSelected = _selectedShopId == shop.id;
        return Padding(
          padding: EdgeInsets.only(
            bottom: responsive.responsivePadding(mobilePadding: 10),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedShopId = shop.id;
              });
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 12),
                vertical: responsive.responsivePadding(mobilePadding: 14),
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.white,
                border: isSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFFF7F7F8),
                        width: 1,
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainText,
                    ),
                  ),
                  if (shop.address != null && shop.address!.isNotEmpty) ...[
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 4),
                    ),
                    Text(
                      shop.address!,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: responsive.responsiveFontSize(mobileSize: 13),
                        fontWeight: FontWeight.w400,
                        color: AppColors.inactiveText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return ResponsivePadding(
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _selectedShopId == null
              ? null
              : () {
                  context.push("/report/complete", extra: _selectedShopId);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            animationDuration: Duration.zero,
            disabledBackgroundColor: AppColors.lightGrey,
            disabledForegroundColor: AppColors.inactiveText,
          ),
          child: Text(
            "제보 완료하기",
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

