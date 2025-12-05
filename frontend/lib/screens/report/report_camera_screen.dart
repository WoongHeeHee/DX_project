import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../data/services/photo_service.dart';
import '../../utils/permissions.dart';

class ReportCameraScreen extends StatefulWidget {
  const ReportCameraScreen({super.key});

  @override
  State<ReportCameraScreen> createState() => _ReportCameraScreenState();
}

class _ReportCameraScreenState extends State<ReportCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isUploading = false;

  Future<void> _takePicture() async {
    try {
      // 위치 권한 확인
      final position = await PermissionHelper.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 권한이 필요합니다.')),
          );
        }
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        setState(() {
          _image = image;
          _isUploading = true;
        });

        // 사진 업로드
        final photoService = Provider.of<PhotoService>(context, listen: false);
        try {
          final imageBytes = await File(image.path).readAsBytes();
          final now = DateTime.now();
          
          // 업로드 초기화
          final uploadInit = await photoService.initPhotoUpload(
            lat: position.latitude,
            lng: position.longitude,
            takenAt: now,
            isMember: false,
          );
          
          // S3에 업로드
          await photoService.uploadPhotoToS3(
            presignedUrl: uploadInit.presignedUrl,
            imageBytes: imageBytes,
          );
          
          // 업로드 완료 알림
          await photoService.completePhotoUpload(
            uploadToken: uploadInit.uploadToken,
            s3Key: uploadInit.s3Key,
            lat: position.latitude,
            lng: position.longitude,
            takenAt: now,
          );

          if (mounted) {
            context.push('/report/shop-select', extra: {
              'image': image,
              'lat': position.latitude,
              'lng': position.longitude,
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('사진 업로드 실패: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 촬영 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 촬영'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(File(_image!.path), height: 200)
            else
              const Icon(Icons.camera_alt, size: 100),
            const SizedBox(height: 40),
            if (_isUploading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _takePicture,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('사진 촬영'),
              ),
          ],
        ),
      ),
    );
  }
}

