import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/enums.dart';

class OnboardingLanguageScreen extends StatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  State<OnboardingLanguageScreen> createState() => _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState extends State<OnboardingLanguageScreen> {
  UserLocale? _selectedLocale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('언어 선택'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            '언어를 선택해주세요',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ...UserLocale.values.map((locale) => RadioListTile<UserLocale>(
            title: Text(locale.displayName),
            value: locale,
            groupValue: _selectedLocale,
            onChanged: (value) {
              setState(() {
                _selectedLocale = value;
              });
            },
          )),
          const Spacer(),
          ElevatedButton(
            onPressed: _selectedLocale == null
                ? null
                : () {
                    // 선택한 언어를 다음 화면으로 전달
                    context.push('/onboarding/name-input', extra: _selectedLocale);
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('선택 완료'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

