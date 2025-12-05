import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/enums.dart';

class OnboardingMain1Screen extends StatefulWidget {
  const OnboardingMain1Screen({super.key});

  @override
  State<OnboardingMain1Screen> createState() => _OnboardingMain1ScreenState();
}

class _OnboardingMain1ScreenState extends State<OnboardingMain1Screen> {
  String? _selectedCountry;
  String? _selectedBirth; // YYYY-MM 형식
  int _spiceLevel = 3;
  String _locale = 'ko';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic> && extra['locale'] != null) {
      _locale = extra['locale'] as String;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('온보딩'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              '정보를 입력해주세요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // 국적 선택 (간단한 예시)
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: const InputDecoration(labelText: '국적'),
              items: const [
                DropdownMenuItem(value: 'US', child: Text('미국')),
                DropdownMenuItem(value: 'CN', child: Text('중국')),
                DropdownMenuItem(value: 'JP', child: Text('일본')),
                DropdownMenuItem(value: 'KR', child: Text('한국')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                });
              },
            ),
            const SizedBox(height: 20),
            // 나이 선택 (YYYY-MM)
            TextField(
              decoration: const InputDecoration(
                labelText: '생년월일 (YYYY-MM)',
                hintText: '1990-01',
              ),
              onChanged: (value) {
                setState(() {
                  _selectedBirth = value;
                });
              },
            ),
            const SizedBox(height: 20),
            // 맵기 선택
            const Text('맵기 수준'),
            Slider(
              value: _spiceLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '🔥' * _spiceLevel,
              onChanged: (value) {
                setState(() {
                  _spiceLevel = value.toInt();
                });
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedCountry == null || _selectedBirth == null
                  ? null
                  : () {
                      context.push('/onboarding/main-2', extra: {
                        'country': _selectedCountry,
                        'birth': _selectedBirth,
                        'spiceLevel': _spiceLevel,
                        'locale': _locale,
                      });
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Next Page'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

