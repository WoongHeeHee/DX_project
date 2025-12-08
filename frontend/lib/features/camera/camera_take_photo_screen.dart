// lib/features/camera/camera_take_photo_screen.dart

import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:go_router/go_router.dart";
import "../../core/theme/app_colors.dart";

class CameraTakePhotoScreen extends StatefulWidget {
  final String? returnPath;

  const CameraTakePhotoScreen({super.key, this.returnPath});

  @override
  State<CameraTakePhotoScreen> createState() => _CameraTakePhotoScreenState();
}

class _CameraTakePhotoScreenState extends State<CameraTakePhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isTaking = false;

  @override
  void initState() {
    super.initState();
    _autoTake();
  }

  Future<void> _autoTake() async {
    if (_isTaking) return;
    _isTaking = true;
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted) return;

      final router = GoRouter.of(context);
      final target = widget.returnPath ?? '/map';
      // 업로드/처리 로직은 후속 구현; 현재는 성공 화면으로 이동
      router.go(
        '/camera/success',
        extra: {'returnPath': target, 'image': image},
      );
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
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

