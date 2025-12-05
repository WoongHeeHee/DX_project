// lib/features/report/report_camera_screen.dart

import "dart:io";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/widgets/responsive_padding.dart";
import "../../core/theme/app_colors.dart";
import "report_store_select_screen.dart";

class ReportCameraScreen extends StatefulWidget {
  const ReportCameraScreen({super.key});

  @override
  State<ReportCameraScreen> createState() => _ReportCameraScreenState();
}

class _ReportCameraScreenState extends State<ReportCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  Future<void> _capturePhoto() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 위치 정보 가져오기 (웹에서는 geolocator 패키지 사용)
      // TODO: 실제 위치 정보 가져오기 구현
      _latitude = 37.5665; // 임시 값
      _longitude = 126.9780; // 임시 값

      // 카메라로 사진 촬영
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _capturedImage = File(image.path);
          _isLoading = false;
        });

        // 촬영 완료 후 주변 가게 선택 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportStoreSelectScreen(
              image: _capturedImage!,
              latitude: _latitude!,
              longitude: _longitude!,
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("사진 촬영에 실패했습니다: $e"),
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

    return Scaffold(
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
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.mainText,
                  ),
                  Expanded(
                    child: Text(
                      "사진 촬영",
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: responsive.responsiveFontSize(mobileSize: 20),
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                ],
              ),
              SizedBox(height: responsive.responsivePadding(mobilePadding: 20)),
              // 카메라 프리뷰 영역
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 80,
                              color: AppColors.subText,
                            ),
                            SizedBox(height: responsive.responsivePadding(mobilePadding: 16)),
                            Text(
                              "카메라를 실행하여\n사진을 촬영해주세요",
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(
                                fontSize: responsive.responsiveFontSize(mobileSize: 16),
                                color: AppColors.subText,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              // 촬영 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _capturePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.responsivePadding(mobilePadding: 16),
                    ),
                  ),
                  child: Text(
                    "사진 촬영",
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
    );
  }
}

