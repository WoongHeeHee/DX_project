// lib/features/camera/camera_take_photo_screen.dart

import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:go_router/go_router.dart";
import "../../core/theme/app_colors.dart";
import "../../data/repositories/api_repository.dart";
import "../../utils/permissions.dart";

class CameraTakePhotoScreen extends StatefulWidget {
  final String? returnPath;

  const CameraTakePhotoScreen({super.key, this.returnPath});

  @override
  State<CameraTakePhotoScreen> createState() => _CameraTakePhotoScreenState();
}

class _CameraTakePhotoScreenState extends State<CameraTakePhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isTaking = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _autoTake();
  }

  Future<void> _autoTake() async {
    if (_isTaking) return;
    _isTaking = true;
    
    try {
      // 위치 권한 확인
      final position = await PermissionHelper.getCurrentPosition();
      if (position == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 필요합니다.')),
        );
        GoRouter.of(context).go(widget.returnPath ?? '/map');
        return;
      }

      // 사진 촬영
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted || image == null) {
        if (mounted) {
          GoRouter.of(context).go(widget.returnPath ?? '/map');
        }
        return;
      }

      // 업로드 시작
      setState(() {
        _isUploading = true;
      });

      // 사진 업로드
      final photoService = ApiRepository().photoService;
      try {
        // XFile.readAsBytes()는 웹과 모바일 모두에서 작동합니다
        final imageBytes = await image.readAsBytes();
        
        // 1. Presigned URL 발급 (새 API 스펙)
        final presignResponse = await photoService.presignPhotoUpload();
        
        // 2. S3에 직접 업로드
        await photoService.uploadPhotoToS3(
          presignedUrl: presignResponse.uploadUrl,
          imageBytes: imageBytes,
        );
        
        // 3. 업로드 완료 알림 (새 API 스펙)
        await photoService.uploadPhoto(
          photoUrl: presignResponse.fileUrl,
          lat: position.latitude,
          lng: position.longitude,
          photoType: 'review', // 회원 리뷰용 사진
        );

        if (!mounted) return;
        
        // 성공 화면으로 이동
        final router = GoRouter.of(context);
        final target = widget.returnPath ?? '/map';
        router.go(
          '/camera/success',
          extra: {'returnPath': target, 'image': image},
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 업로드 실패: $e')),
        );
        GoRouter.of(context).go(widget.returnPath ?? '/map');
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 촬영 실패: $e')),
      );
      GoRouter.of(context).go(widget.returnPath ?? '/map');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading)
              const CircularProgressIndicator()
            else
              const CircularProgressIndicator(),
            if (_isUploading) ...[
              const SizedBox(height: 16),
              Text(
                '사진을 업로드하고 있습니다...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

