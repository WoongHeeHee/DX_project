import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/enums.dart';

class OnboardingNameInputScreen extends StatefulWidget {
  const OnboardingNameInputScreen({super.key});

  @override
  State<OnboardingNameInputScreen> createState() => _OnboardingNameInputScreenState();
}

class _OnboardingNameInputScreenState extends State<OnboardingNameInputScreen> {
  final _nameController = TextEditingController();
  UserLocale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이전 화면에서 전달된 locale 받기
    final extra = GoRouterState.of(context).extra;
    if (extra is UserLocale) {
      _locale = extra;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isValidName(String name) {
    // 특수문자만 있는지 확인
    return name.trim().isNotEmpty && 
           name.trim().replaceAll(RegExp(r'[^\w\s]'), '').isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이름 입력'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              '본인의 이름을 입력해주세요',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nameController.text.isEmpty || !_isValidName(_nameController.text)
                  ? null
                  : () {
                      context.push(
                        '/onboarding/name-generate',
                        extra: _nameController.text.trim(),
                      );
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}

