import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";

class ReportShopSelectScreen extends StatefulWidget {
  const ReportShopSelectScreen({super.key});

  @override
  State<ReportShopSelectScreen> createState() => _ReportShopSelectScreenState();
}

class _ReportShopSelectScreenState extends State<ReportShopSelectScreen> {
  String? _selectedShopId;

  // 더미 데이터 (나중에 DB에서 가져올 데이터)
  final List<Map<String, String>> _dummyShops = [
    {
      "id": "1",
      "name": "더미 가게 1",
      "address": "서울시 강남구 테헤란로 123",
    },
    {
      "id": "2",
      "name": "더미 가게 2",
      "address": "서울시 강남구 테헤란로 456",
    },
    {
      "id": "3",
      "name": "더미 가게 3",
      "address": "서울시 강남구 테헤란로 789",
    },
  ];

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
    return Column(
      children: _dummyShops.map((shop) {
        final isSelected = _selectedShopId == shop["id"];
        return Padding(
          padding: EdgeInsets.only(
            bottom: responsive.responsivePadding(mobilePadding: 10),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedShopId = shop["id"];
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
                    shop["name"] ?? "",
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainText,
                    ),
                  ),
                  if (shop["address"] != null) ...[
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 4),
                    ),
                    Text(
                      shop["address"]!,
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
