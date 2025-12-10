// lib/features/my/saved_foods_screen.dart

import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../data/models/menu_models.dart";
import "../../data/repositories/api_repository.dart";

class SavedFoodsScreen extends StatefulWidget {
  const SavedFoodsScreen({super.key});

  @override
  State<SavedFoodsScreen> createState() => _SavedFoodsScreenState();
}

class _SavedFoodsScreenState extends State<SavedFoodsScreen> {
  final _apiRepository = ApiRepository();
  List<MenuItemModel> _savedFoods = []; // 찜한 음식 리스트
  bool _isLoading = true;
  String _selectedCategory = "전체"; // 선택된 카테고리
  Map<String, bool> _tempSavedStates = {}; // 임시 저장 상태 (화면을 나가기 전까지 유지)

  // 카테고리 필터 (처음부터 모두 있음)
  final List<Map<String, String>> _categories = [
    {"value": "전체", "label": "전체"},
    {"value": "Meals", "label": "식사"},
    {"value": "Snacks", "label": "간식"},
    {"value": "Sweets", "label": "디저트"},
    {"value": "Drink", "label": "음료"},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedFoods();
  }

  Future<void> _loadSavedFoods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: API 호출하여 찜한 음식 리스트 가져오기
      // final foods = await _apiRepository.menuService.getSavedMenuItems();

      // 더미 데이터 (화면 확인용)
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _savedFoods = [
          MenuItemModel(
            id: "ME001",
            name: "떡볶이",
            category: "Meals",
            spiceLevel: 3,
            repImageUrl: "https://placehold.co/200x200",
          ),
          MenuItemModel(
            id: "ME002",
            name: "김밥",
            category: "Meals",
            spiceLevel: 1,
            repImageUrl: "https://placehold.co/200x200",
          ),
          MenuItemModel(
            id: "ME003",
            name: "순대",
            category: "Snacks",
            spiceLevel: 2,
            repImageUrl: "https://placehold.co/200x200",
          ),
          MenuItemModel(
            id: "ME004",
            name: "호떡",
            category: "Sweets",
            spiceLevel: 1,
            repImageUrl: "https://placehold.co/200x200",
          ),
          MenuItemModel(
            id: "ME005",
            name: "붕어빵",
            category: "Sweets",
            spiceLevel: 1,
            repImageUrl: "https://placehold.co/200x200",
          ),
          MenuItemModel(
            id: "ME006",
            name: "아이스크림",
            category: "Sweets",
            spiceLevel: 1,
            repImageUrl: "https://placehold.co/200x200",
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("찜한 음식 로드 실패: $e");
    }
  }

  void _toggleSaveFood(String menuItemId) {
    setState(() {
      // 임시 저장 상태 토글 (화면을 나가기 전까지는 UI만 변경)
      _tempSavedStates[menuItemId] = !(_tempSavedStates[menuItemId] ?? true);
    });
    // TODO: 실제 API 호출은 화면을 나갔다가 다시 들어올 때 적용
  }

  bool _isFoodSaved(String menuItemId) {
    // 임시 저장 상태가 있으면 그것을 사용, 없으면 기본값 true
    return _tempSavedStates[menuItemId] ?? true;
  }

  String _getMenuImageUrl(MenuItemModel menu) {
    // S3 플레이스홀더 URL 생성
    final menuName = menu.name;
    final menuId = menu.id;
    return "https://dnzeuzpu74ulj.cloudfront.net/placeholders/Menu_all/$menuName/${menuName}1_$menuId.png";
  }

  List<MenuItemModel> get _filteredFoods {
    final foods = _selectedCategory == "전체"
        ? _savedFoods
        : _savedFoods
            .where((food) => food.category == _selectedCategory)
            .toList();
    // 임시 저장 상태가 false인 항목은 필터링에서 제외 (화면을 나가기 전까지는 표시)
    return foods.where((food) => _isFoodSaved(food.id)).toList();
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
            // 상단 헤더
            _buildHeader(responsive, textTheme),
            // 대제목과 필터 칩
            _buildTitleAndFilters(responsive, textTheme),
            // 찜한 음식 리스트
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : _buildFoodList(responsive, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
        vertical: responsive.responsivePadding(mobilePadding: 16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.chevron_left,
              size: responsive.responsiveIconSize(mobileSize: 24),
              color: AppColors.mainText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleAndFilters(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final totalCount = _savedFoods.length;

    return Padding(
      padding: EdgeInsets.only(
        left: responsive.responsivePadding(mobilePadding: 20),
        right: responsive.responsivePadding(mobilePadding: 20),
        top: responsive.responsivePadding(mobilePadding: 16),
        bottom: responsive.responsivePadding(mobilePadding: 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 대제목: "찜한 메뉴 00개"
          RichText(
            text: TextSpan(
              style: textTheme.titleLarge?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 20),
                fontWeight: FontWeight.w600,
                color: AppColors.mainText,
              ),
              children: [
                TextSpan(text: "찜한 메뉴 "),
                TextSpan(
                  text: "$totalCount",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: responsive.responsiveFontSize(mobileSize: 22),
                  ),
                ),
                TextSpan(text: "개"),
              ],
            ),
          ),
          SizedBox(
            height: responsive.responsivePadding(mobilePadding: 16),
          ),
          // 필터 칩들
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category["value"];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category["value"]!;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        right: responsive.responsivePadding(mobilePadding: 6),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            responsive.responsivePadding(mobilePadding: 12),
                        vertical:
                            responsive.responsivePadding(mobilePadding: 10),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        category["label"]!,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize:
                              responsive.responsiveFontSize(mobileSize: 12),
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected ? AppColors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final filteredFoods = _filteredFoods;

    if (filteredFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "아직 맛있는 걸 못 찾으셨나요?",
              style: textTheme.bodyMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 16),
                fontWeight: FontWeight.w400,
                color: AppColors.inactiveText,
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 20),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 탐색 화면으로 이동
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    vertical:
                        responsive.responsivePadding(mobilePadding: 16) * 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  "찾으러 가기",
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 20),
        vertical: responsive.responsivePadding(mobilePadding: 8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: responsive.responsivePadding(mobilePadding: 12),
          mainAxisSpacing: responsive.responsivePadding(mobilePadding: 16),
          childAspectRatio: 0.75, // 이미지 카드 비율
        ),
        itemCount: filteredFoods.length,
        itemBuilder: (context, index) {
          return _buildFoodCard(responsive, textTheme, filteredFoods[index]);
        },
      ),
    );
  }

  Widget _buildFoodCard(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MenuItemModel food,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 카드
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _getMenuImageUrl(food),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFFF3EEF3));
                },
              ),
            ),
          ),
        ),
        SizedBox(
          height: responsive.responsivePadding(mobilePadding: 8),
        ),
        // 메뉴명과 찜 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                food.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: responsive.responsivePadding(mobilePadding: 8),
            ),
            _buildUnsaveButton(responsive, textTheme, food),
          ],
        ),
      ],
    );
  }

  Widget _buildUnsaveButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    MenuItemModel food,
  ) {
    final isSaved = _isFoodSaved(food.id);

    return GestureDetector(
      onTap: () {
        _toggleSaveFood(food.id);
      },
      child: Icon(
        isSaved ? Icons.favorite : Icons.favorite_border,
        size: responsive.responsiveIconSize(mobileSize: 20),
        color: isSaved ? AppColors.primary : AppColors.inactiveText,
      ),
    );
  }
}

