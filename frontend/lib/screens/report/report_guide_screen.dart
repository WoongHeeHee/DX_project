import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportGuideScreen extends StatelessWidget {
  const ReportGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가게 제보 가이드'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              '가게 제보 안내',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('프로젝트 설명...'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                context.push('/report/camera');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('촬영 시작'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

