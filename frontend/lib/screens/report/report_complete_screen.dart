import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportCompleteScreen extends StatelessWidget {
  const ReportCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('제보 완료'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '제보 완료',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('감사합니다!'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                context.go('/welcome');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
              child: const Text('최초화면 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}

