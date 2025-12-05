// lib/features/search/text_search_screen.dart

import "package:flutter/material.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../data/repositories/api_repository.dart";
import "../../data/services/user_service.dart";
import "models/search_result_model.dart";
import "search_result_screen.dart";
import "search_error_screen.dart";

class TextSearchScreen extends StatefulWidget {
  const TextSearchScreen({super.key});

  @override
  State<TextSearchScreen> createState() => _TextSearchScreenState();
}

class _TextSearchScreenState extends State<TextSearchScreen> {
  final _apiRepository = ApiRepository();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  double _keyboardHeight = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final currentKeyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 키보드가 올라오면 높이를 저장 (한 번이라도 올라왔으면 그 위치 고정)
    if (currentKeyboardHeight > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _keyboardHeight != currentKeyboardHeight) {
          setState(() {
            _keyboardHeight = currentKeyboardHeight;
          });
        }
      });
    }

    return GestureDetector(
      onTap: () {
        // 키보드 바깥 영역 터치 시 키보드 닫기
        FocusScope.of(context).unfocus();
      },
      child: LoadingOverlay(
        isLoading: _isLoading,
        child: Scaffold(
          backgroundColor: AppColors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
          child: Column(
            children: [
              // 상단 제목과 입력 영역
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: AppColors.white,
                    child: Column(
                      children: [
                        _buildContent(responsive, textTheme),
                        // 하단 이미지 배너 (키보드가 올라오지 않았을 때만 표시)
                        if (currentKeyboardHeight == 0)
                          _buildBanner(responsive),
                        // 메뉴 찾기 버튼 (스크롤 영역 내부에 배치)
                        _buildSearchButton(
                          responsive,
                          textTheme,
                          currentKeyboardHeight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ResponsiveHelper responsive, TextTheme textTheme) {
    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: responsive.responsivePadding(mobilePadding: 8)),
          // 제목
          Text(
            "궁금한 시장 메뉴를 알려드릴게요",
            style: textTheme.titleLarge?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 20),
              fontWeight: FontWeight.w500,
              color: AppColors.mainText,
              height: 1.30,
            ),
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
          // 입력 카드
          _buildInputCard(responsive, textTheme),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 4)),
        ],
      ),
    );
  }

  Widget _buildInputCard(ResponsiveHelper responsive, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 12),
        vertical: responsive.responsivePadding(mobilePadding: 10),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05), // 0x0CFD312E
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 라벨
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "설명 입력",
                style: textTheme.bodySmall?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 12),
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 55.75), // 공간 유지
            ],
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 6)),
          // 텍스트 입력 영역
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: responsive.isMobile ? 114 : 130,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                responsive.responsivePadding(mobilePadding: 10),
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 4,
                textInputAction: TextInputAction.newline, // 엔터 키로 줄바꿈만
                keyboardType: TextInputType.multiline,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 14),
                  fontWeight: FontWeight.w700, // 볼드
                  color: AppColors.mainText,
                  height: 1.50,
                ),
                decoration: InputDecoration(
                  hintText:
                      "예: 매콤한 떡볶이, 달콤한 호떡, 바삭한 튀김 등\n원하는 메뉴의 맛, 재료, 분위기를 자유롭게 적어주세요",
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 14),
                    fontWeight: FontWeight.w300,
                    color: AppColors.primary, // 메인 컬러
                    height: 1.50,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false, // 배경색 없음
                ),
                onSubmitted: (value) {
                  // 엔터 키로 검색되지 않도록 아무 동작도 하지 않음
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSearch() async {
    final query = _textController.text.trim();

    // 텍스트가 비어있거나 공백만 입력한 경우
    if (query.isEmpty) {
      _showEmptyTextDialog();
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 텍스트 검색 API 호출
      final locale = await _apiRepository.userService.getLocale();
      final menuItems = await _apiRepository.searchService.searchMenuItems(
        query: query,
        limit: 1, // 첫 번째 결과만 사용
      );

      if (mounted) {
        if (menuItems.isEmpty) {
          // 검색 결과가 없는 경우 에러 화면
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchErrorScreen(),
            ),
          );
        } else {
          // 첫 번째 결과 사용
          final menuItem = menuItems.first;
          
          // SearchResultModel로 변환
          final searchResult = SearchResultModel(
            id: menuItem.id,
            menuName: menuItem.getNameByLocale(locale),
            imageUrl: menuItem.repImageUrl ?? '',
            description: menuItem.getDescriptionByLocale(locale) ?? '',
            nearestMarketName: null, // TODO: 시장 정보 추가 필요
            nearestMarketId: null,
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchResultScreen(result: searchResult),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("검색 중 오류 발생: $e");
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchErrorScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 더미 검색 결과 생성 (서버 연결 전 임시)
  SearchResultModel _createDummySearchResult(String query) {
    // 쿼리에 따라 다른 더미 데이터 반환
    // 실제로는 서버에서 받아올 데이터
    return SearchResultModel(
      id: "search_${DateTime.now().millisecondsSinceEpoch}",
      menuName: "계란빵",
      imageUrl: "https://placehold.co/343x220",
      description:
          "촉촉하고 따뜻한 계란이 가득 들어간 길거리 간식이에요. 출출할 때 하나만 먹어도 든든하고, 시장을 지나가다 향만 맡아도 한 번쯤은 꼭 먹고 싶은 메뉴죠.",
      nearestMarketName: "광장시장",
      nearestMarketId: "market_1",
    );
  }

  void _showEmptyTextDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final responsive = context.responsive;
        final textTheme = Theme.of(context).textTheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "텍스트를 입력해주세요",
            style: textTheme.titleMedium?.copyWith(
              fontSize: responsive.responsiveFontSize(mobileSize: 16),
              fontWeight: FontWeight.w500,
              color: AppColors.mainText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
              },
              child: Text(
                "확인",
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    double keyboardHeight,
  ) {
    // 로직:
    // 1. 화면 진입 초기: 버튼이 가장 아래 (기본 여백)
    // 2. 키보드 올라오면: 키보드 높이 바로 위에 버튼 (현재 키보드 높이 + 여유 공간)
    // 3. 키보드가 한 번이라도 올라왔으면: 그 위치에 버튼 고정 (저장된 키보드 높이 + 여유 공간)
    final bottomPadding = _keyboardHeight > 0
        ? _keyboardHeight +
              responsive.responsivePadding(
                mobilePadding: 8,
              ) // 저장된 키보드 높이 + 여유 공간
        : (keyboardHeight > 0
              ? keyboardHeight +
                    responsive.responsivePadding(
                      mobilePadding: 8,
                    ) // 현재 키보드 높이 + 여유 공간
              : responsive.responsivePadding(mobilePadding: 4)); // 기본 여백

    return ResponsivePadding(
      mobilePadding: 16,
      tabletPadding: 24,
      desktopPadding: 32,
      child: Padding(
        padding: EdgeInsets.only(
          top: responsive.responsivePadding(mobilePadding: 4),
          bottom: bottomPadding,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.responsivePadding(mobilePadding: 16),
                vertical: responsive.responsivePadding(mobilePadding: 12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              "메뉴 찾기",
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontSize: responsive.responsiveFontSize(mobileSize: 15),
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(ResponsiveHelper responsive) {
    return Container(
      width: double.infinity,
      height: responsive.isMobile ? 291 : 350,
      decoration: const BoxDecoration(color: AppColors.white),
      child: Image.network(
        "https://placehold.co/375x291",
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: AppColors.white);
        },
      ),
    );
  }
}
