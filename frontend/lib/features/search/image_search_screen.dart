// lib/features/search/image_search_screen.dart

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../core/widgets/loading_overlay.dart";
import "../../core/widgets/xfile_image.dart";
import "../../data/repositories/api_repository.dart";
import "../../utils/permissions.dart";
import "models/search_result_model.dart";

class ImageSearchScreen extends StatefulWidget {
  final XFile? initialImage;
  final String? previousText;

  const ImageSearchScreen({super.key, this.initialImage, this.previousText});

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
  bool _isPickingImage = false; // 이미지 선택 중 상태

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
    // 이전 입력값이 있으면 복원
    if (widget.previousText != null && widget.previousText!.isNotEmpty) {
      _textController.text = widget.previousText!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return; // 이미 선택 중이면 중복 호출 방지
    
    setState(() {
      _isPickingImage = true;
    });

    try {
      // 카메라인 경우 권한 확인 (웹에서는 자동으로 처리됨)
      if (source == ImageSource.camera) {
        // ImagePicker가 자동으로 권한을 요청하지만, 에러 처리를 위해 try-catch 사용
        debugPrint("카메라 촬영 시작");
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // 이미지 품질 설정
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
          _isPickingImage = false;
        });
        debugPrint("이미지 선택 완료: ${image.path}");
      } else if (source == ImageSource.camera && image == null) {
        // 카메라에서 취소한 경우 사용자에게 알림 (선택사항 - 취소는 정상 동작)
        if (mounted) {
          setState(() {
            _isPickingImage = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isPickingImage = false;
          });
        }
      }
    } on PlatformException catch (e) {
      // 플랫폼별 에러 처리
      String errorMessage = '이미지를 선택할 수 없습니다.';
      if (e.code == 'camera_access_denied') {
        errorMessage = '카메라 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
      } else if (e.code == 'photo_access_denied') {
        errorMessage = '갤러리 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      debugPrint("이미지 선택 에러: $e");
    } catch (e) {
      debugPrint("이미지 선택 에러: $e");
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 선택할 수 없습니다: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

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
          backgroundColor: AppColors.white,
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
              height: 26 / 20, // Figma: lineHeight 26px / fontSize 20px
              fontFamily: 'Inter',
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
          height: responsive.isMobile ? 220 : 250,
          decoration: BoxDecoration(
            color: AppColors.softPurpleBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
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
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.05),
          width: 1,
        ),
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
                  height: 1.2,
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
                borderRadius: BorderRadius.circular(6),
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
                  fontWeight: FontWeight.w300,
                  color: AppColors.mainText,
                  height: 21 / 14, // Figma: lineHeight 21px / fontSize 14px
                  fontFamily: 'Inter',
                ),
                decoration: InputDecoration(
                  hintText: "사진에 덧붙일 설명이 있다면 적어주세요!",
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    fontSize: responsive.responsiveFontSize(mobileSize: 14),
                    fontWeight: FontWeight.w300,
                    color: AppColors.primary,
                    height: 21 / 14, // Figma: lineHeight 21px / fontSize 14px
                    fontFamily: 'Inter',
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
                
                // 1. 위치 정보 가져오기
                final position = await PermissionHelper.getCurrentPosition();
                if (position == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('위치 권한이 필요합니다. 위치 권한을 허용해주세요.'),
                      ),
                );
                  }
                  return;
                }
                
                final lat = position.latitude;
                final lng = position.longitude;
                
                // 2. 이미지 파일 읽기 (메모리에서)
                final imageBytes = await _selectedImage!.readAsBytes();
                
                // 3. 검색용 사진은 저장하지 않고 직접 검색 API 호출
                // 검색용 사진은 DB나 S3에 저장하지 않음
                final locale = await _apiRepository.userService.getLocale();
                final searchResults = await _apiRepository.searchService.imageSearchUpload(
                  imageBytes: imageBytes,
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
                      extra: {
                        'result': searchResult,
                        'previousScreenType': 'image',
                        'previousTextInput': query,
                        'previousImage': _selectedImage,
                      },
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

}
