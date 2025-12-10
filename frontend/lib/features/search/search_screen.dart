// lib/features/search/search_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _handleImageSearch() async {
    try {
      // 이미지 소스 선택 다이얼로그 표시
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          final responsive = context.responsive;
          final textTheme = Theme.of(context).textTheme;

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    size: responsive.responsiveIconSize(mobileSize: 24),
                    color: AppColors.primary,
                  ),
                  title: Text(
                    "카메라로 촬영",
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 16),
                      color: AppColors.mainText,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    size: responsive.responsiveIconSize(mobileSize: 24),
                    color: AppColors.primary,
                  ),
                  title: Text(
                    "갤러리에서 선택",
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 16),
                      color: AppColors.mainText,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                SizedBox(height: responsive.responsivePadding(mobilePadding: 8)),
              ],
            ),
          );
        },
      );

      if (source != null && mounted) {
        // 약간의 지연을 두고 이미지 선택 (플러그인 초기화 대기)
        await Future.delayed(const Duration(milliseconds: 100));
        
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 85, // 이미지 품질 설정
        );
        
        if (image != null && mounted) {
          context.push(
            '/search/image',
            extra: {'initialImage': image},
          );
        }
      }
    } catch (e) {
      debugPrint("이미지 선택 에러: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("이미지를 선택할 수 없습니다. 앱을 재시작해주세요."),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
            // 상단 제목
            _buildHeader(responsive, textTheme),
            // 검색 옵션 카드들
            Expanded(
              child: _buildSearchOptions(context, responsive, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Padding(
        padding: EdgeInsets.only(
          top: responsive.responsivePadding(mobilePadding: 8),
          bottom: responsive.responsivePadding(mobilePadding: 4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => context.go('/map'),
              icon: Icon(
                Icons.arrow_back,
                size: responsive.responsiveIconSize(mobileSize: 24),
                color: AppColors.mainText,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
        child: Text(
          "궁금한 시장 메뉴를 알려드릴게요",
          style: textTheme.titleLarge?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 20),
            fontWeight: FontWeight.w500,
            color: AppColors.mainText,
            height: 26 / 20, // Figma: lineHeight 26px / fontSize 20px
            fontFamily: 'Inter',
          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOptions(
    BuildContext context,
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: responsive.responsivePadding(mobilePadding: 4)),
          // 사진으로 찾기 카드
          _buildSearchCard(
            context,
            responsive,
            textTheme,
            icon: Icons.camera_alt,
            title: "사진으로 찾기",
            description: "시장 음식 사진을 첨부하면 어떤 메뉴인\n지 분석하고 비슷한 메뉴를 추천해드려요.",
            onTap: _handleImageSearch,
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 18)),
          // 텍스트로 찾기 카드
          _buildSearchCard(
            context,
            responsive,
            textTheme,
            icon: Icons.edit,
            title: "텍스트로 찾기",
            description: "메뉴 이름이나 맛, 재료, 분위기를 자유\n롭게 적어주면 어울리는 시장 메뉴를 찾\n아드려요.",
            onTap: () {
              context.push('/search/text');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(
    BuildContext context,
    ResponsiveHelper responsive,
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(responsive.responsivePadding(mobilePadding: 16)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            Container(
              width: responsive.responsiveIconSize(mobileSize: 40),
              height: responsive.responsiveIconSize(mobileSize: 40),
              decoration: BoxDecoration(
                color: AppColors.softGreyBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: responsive.responsiveIconSize(mobileSize: 22),
                color: AppColors.mainText,
              ),
            ),
            SizedBox(width: responsive.responsivePadding(mobilePadding: 12)),
            // 제목과 설명
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 15),
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainText,
                      height: 18.15 / 15, // Figma: lineHeight 18.15px / fontSize 15px
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: responsive.responsivePadding(mobilePadding: 5)),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: responsive.responsiveFontSize(mobileSize: 13),
                      fontWeight: FontWeight.w400,
                      color: AppColors.inactiveText,
                      height: 18.2 / 13, // Figma: lineHeight 18.2px / fontSize 13px
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: responsive.responsivePadding(mobilePadding: 12)),
            // 화살표 아이콘
            Icon(
              Icons.arrow_forward_ios,
              size: responsive.responsiveIconSize(mobileSize: 18),
              color: AppColors.inactiveText,
            ),
          ],
        ),
      ),
    );
  }
}

