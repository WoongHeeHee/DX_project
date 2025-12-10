import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:image_picker/image_picker.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "../../utils/permissions.dart";

class ReportGuideScreen extends StatefulWidget {
  const ReportGuideScreen({super.key});

  @override
  State<ReportGuideScreen> createState() => _ReportGuideScreenState();
}

class _ReportGuideScreenState extends State<ReportGuideScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _showImageSourceDialog() async {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
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
                SizedBox(
                    height: responsive.responsivePadding(mobilePadding: 8)),
              ],
            ),
          ),
        );
      },
    );

    if (source != null && mounted) {
      await _handleImageSelection(source);
    }
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 위치 권한 확인
      final position = await PermissionHelper.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("위치 권한이 필요합니다.")),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 약간의 지연을 두고 이미지 선택 (플러그인 초기화 대기)
      await Future.delayed(const Duration(milliseconds: 100));

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // TODO: 서버 연결 시 주석 해제
        // // 사진 업로드
        // final photoService = Provider.of<PhotoService>(context, listen: false);
        // try {
        //   final imageBytes = await image.readAsBytes();
        //   final now = DateTime.now();
        //
        //   // 업로드 초기화
        //   final uploadInit = await photoService.initPhotoUpload(
        //     lat: position.latitude,
        //     lng: position.longitude,
        //     takenAt: now,
        //     isMember: false,
        //   );
        //
        //   // S3에 업로드
        //   await photoService.uploadPhotoToS3(
        //     presignedUrl: uploadInit.presignedUrl,
        //     imageBytes: imageBytes,
        //   );
        //
        //   // 업로드 완료 알림
        //   await photoService.completePhotoUpload(
        //     uploadToken: uploadInit.uploadToken,
        //     s3Key: uploadInit.s3Key,
        //     lat: position.latitude,
        //     lng: position.longitude,
        //     takenAt: now,
        //   );
        //
        //   if (mounted) {
        //     // 로딩 화면으로 이동 (모델 판별 시간 벌기)
        //     context.push("/report/loading", extra: {
        //       "image": image,
        //       "lat": position.latitude,
        //       "lng": position.longitude,
        //     });
        //   }
        // } catch (e) {
        //   if (mounted) {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(content: Text("사진 업로드 실패: $e")),
        //     );
        //   }
        // } finally {
        //   if (mounted) {
        //     setState(() {
        //       _isLoading = false;
        //     });
        //   }
        // }

        // 임시: 서버 연결 없이 바로 로딩 화면으로 이동
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          context.push("/report/loading", extra: {
            "image": image,
            "lat": position.latitude,
            "lng": position.longitude,
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("이미지 선택 실패: $e")),
        );
        setState(() {
          _isLoading = false;
        });
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  Expanded(
                    child: ResponsivePadding(
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildContent(context, textTheme),
                          ),
                        ],
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

  Widget _buildContent(BuildContext context, TextTheme textTheme) {
    final responsive = context.responsive;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: responsive.responsiveFontSize(mobileSize: 330),
            child: Image.asset(
              "assets/images/lg_slogan_login.png",
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  "이미지를 불러올 수 없습니다",
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.subText,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.mainText,
              ),
              children: [
                const TextSpan(
                  text: "영업 중인 가게를 촬영해주세요! \n\n ",
                ),
                TextSpan(
                  text: "음식 위주로 촬영",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainText,
                  ),
                ),
                const TextSpan(
                  text: "하시면 \n 더 정확한 정보를 제공할 수 있습니다.",
                ),
              ],
            ),
          ),
        ],
      ),
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
          onPressed: _isLoading ? null : _showImageSourceDialog,
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
          ),
          child: Text(
            "촬영하기",
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
