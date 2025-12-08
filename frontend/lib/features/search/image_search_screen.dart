// lib/features/search/image_search_screen.dart

import "dart:typed_data";
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../core/widgets/xfile_image.dart";
import "../../data/repositories/api_repository.dart";
import "models/search_result_model.dart";

class ImageSearchScreen extends StatefulWidget {
  final XFile? initialImage;

  const ImageSearchScreen({super.key, this.initialImage});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  final ImagePicker _picker = ImagePicker();
  final _apiRepository = ApiRepository();
  XFile? _selectedImage;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  double _keyboardHeight = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint("이미지 선택 에러: $e");
    }
  }

  // 더미 검색 결과 생성 (서버 연결 전 임시) - 현재 사용하지 않음
  // SearchResultModel _createDummySearchResult(String query) {
  //   // 쿼리에 따라 다른 더미 데이터 반환
  //   // 실제로는 서버에서 받아올 데이터
  //   return SearchResultModel(
  //     id: "search_${DateTime.now().millisecondsSinceEpoch}",
  //     menuName: "계란빵",
  //     imageUrl: "https://placehold.co/343x220",
  //     description:
  //         "촉촉하고 따뜻한 계란이 가득 들어간 길거리 간식이에요. 출출할 때 하나만 먹어도 든든하고, 시장을 지나가다 향만 맡아도 한 번쯤은 꼭 먹고 싶은 메뉴죠.",
  //     nearestMarketName: "광장시장",
  //     nearestMarketId: "market_1",
  //   );
  // }

  void _showImageSourceDialog() {
    showModalBottomSheet(
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
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
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
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: responsive.responsivePadding(mobilePadding: 8)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;
    final currentKeyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 키보드가 올라오면 높이를 저장
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
        FocusScope.of(context).unfocus();
      },
      child: LoadingOverlay(
        isLoading: _isLoading,
        child: Scaffold(
          backgroundColor: AppColors.softGreyBackground,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      color: AppColors.white,
                      child: Column(
                        children: [
                          _buildContent(responsive, textTheme),
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
          // 뒤로가기 + 제목
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/search'),
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
              height: 1.30,
            ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
          // 사진 영역
          _buildImageArea(responsive),
          SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
          // 설명 입력 영역
          _buildInputCard(responsive, textTheme),
        ],
      ),
    );
  }

  Widget _buildImageArea(ResponsiveHelper responsive) {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          width: responsive.isMobile ? 159 : 180,
          decoration: BoxDecoration(
            color: AppColors.softPurpleBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: responsive.isMobile ? 220 : 250,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: _selectedImage != null
                      ? XFileImage(
                          image: _selectedImage,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: AppColors.imagePlaceholder,
                            child: Icon(
                              Icons.error,
                              size: responsive.responsiveIconSize(mobileSize: 40),
                              color: AppColors.subText,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.imagePlaceholder,
                          child: Icon(
                            Icons.add_photo_alternate,
                            size: responsive.responsiveIconSize(mobileSize: 40),
                            color: AppColors.subText,
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

  Widget _buildInputCard(ResponsiveHelper responsive, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.responsivePadding(mobilePadding: 12),
        vertical: responsive.responsivePadding(mobilePadding: 10),
      ),
      decoration: BoxDecoration(
        color: AppColors.softPurpleBackground,
        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 55.75),
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 4,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 14),
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainText,
                  height: 1.50,
                ),
                decoration: InputDecoration(
                  hintText: "사진에 덧붙일 설명이 있다면 적어주세요!",
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 14),
                    fontWeight: FontWeight.w300,
                    color: AppColors.primary,
                    height: 1.50,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                onSubmitted: (value) {
                  // 엔터 키로 검색되지 않도록
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
    double keyboardHeight,
  ) {
    // 로직:
    // 1. 화면 진입 초기: 버튼이 가장 아래 (기본 여백)
    // 2. 키보드 올라오면: 키보드 높이 바로 위에 버튼
    // 3. 키보드가 한 번이라도 올라왔으면: 그 위치에 버튼 고정
    final bottomPadding = _keyboardHeight > 0
        ? _keyboardHeight + responsive.responsivePadding(mobilePadding: 8)
        : (keyboardHeight > 0
              ? keyboardHeight + responsive.responsivePadding(mobilePadding: 8)
              : responsive.responsivePadding(mobilePadding: 4));

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
            onPressed: _selectedImage == null ? null : () async {
              if (_isLoading) return;
              
              setState(() {
                _isLoading = true;
              });

              try {
                final query = _textController.text.trim();
                
                // 1. 이미지 업로드 (presigned URL 사용)
                final imageBytes = await _selectedImage!.readAsBytes();
                final now = DateTime.now();
                
                // 위치 정보 가져오기 (웹에서는 geolocator 사용)
                // TODO: 실제 위치 정보 가져오기 구현
                double? lat = 37.5665; // 임시 값
                double? lng = 126.9780; // 임시 값
                
                // 업로드 초기화
                final uploadInit = await _apiRepository.photoService.initPhotoUpload(
                  lat: lat,
                  lng: lng,
                  takenAt: now,
                  isMember: false,
                );
                
                // S3에 업로드
                await _apiRepository.photoService.uploadPhotoToS3(
                  presignedUrl: uploadInit.presignedUrl,
                  imageBytes: Uint8List.fromList(imageBytes),
                );
                
                // 업로드 완료 알림
                await _apiRepository.photoService.completePhotoUpload(
                  uploadToken: uploadInit.uploadToken,
                  s3Key: uploadInit.s3Key,
                  lat: lat,
                  lng: lng,
                  takenAt: now,
                );
                
                // 2. 이미지 URL 생성 (S3 객체 URL)
                // 백엔드에서 presigned download URL을 생성하거나, S3 공개 URL 사용
                // 일단 s3_key를 사용하여 백엔드에서 처리하도록 함
                // TODO: 백엔드에서 이미지 URL을 반환하도록 수정 필요
                final imageUrl = uploadInit.s3Key; // 임시로 s3_key 사용
                
                // 3. 이미지 검색 API 호출
                final locale = await _apiRepository.userService.getLocale();
                final searchResults = await _apiRepository.searchService.imageSearch(
                  imageUrl: imageUrl,
                  userText: query.isEmpty ? null : query,
                  lat: lat,
                  lng: lng,
                );
                
                if (mounted) {
                  if (searchResults.isEmpty) {
                    // 검색 결과가 없는 경우 에러 화면
                    context.push('/search/error');
                  } else {
                    // 첫 번째 결과 사용
                    final result = searchResults.first;
                    final menuItem = result.menuItem;
                    // final nearestShop = result.shopsNearby.isNotEmpty 
                    //     ? result.shopsNearby.first 
                    //     : null; // TODO: 추후 사용 예정
                    
                    // SearchResultModel로 변환
                    final searchResult = SearchResultModel(
                      id: menuItem.id,
                      menuName: menuItem.getNameByLocale(locale),
                      imageUrl: menuItem.repImageUrl ?? '',
                      description: menuItem.getDescriptionByLocale(locale) ?? '',
                      nearestMarketName: null, // TODO: 시장 정보 추가 필요
                      nearestMarketId: null, // TODO: ShopWithDistance에 marketId 필드 추가 필요
                    );
                    
                    context.push(
                      '/search/result',
                      extra: {'result': searchResult},
                    );
                  }
                }
              } catch (e) {
                debugPrint("이미지 검색 중 오류 발생: $e");
                if (mounted) {
                  context.push('/search/error');
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
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
              "결과보기",
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

}
