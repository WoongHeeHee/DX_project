import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../data/services/api_service.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class OnboardingMain2Screen extends StatefulWidget {
  const OnboardingMain2Screen({super.key});

  @override
  State<OnboardingMain2Screen> createState() => _OnboardingMain2ScreenState();
}

class _OnboardingMain2ScreenState extends State<OnboardingMain2Screen> {
  AdventureLevel? _challengeLevel;
  KoreanExperience? _kfoodLevel;
  Map<String, dynamic>? _previousData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_previousData == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic>) {
        _previousData = extra;
      }
    }
  }

  Future<void> _completeOnboarding() async {
    if (_challengeLevel == null || _kfoodLevel == null || _previousData == null) {
      return;
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // locale도 함께 전송 (이전 화면에서 받은 값)
      final response = await apiService.put(
        '/users/complete-onboarding',
        data: {
          ..._previousData!,
          'adventure': _challengeLevel!.value,
          'korean_experience': _kfoodLevel!.value,
          'locale': _previousData!['locale'] ?? 'ko',
        },
      );

      final userData = response.data as Map<String, dynamic>;
      // UserModel.fromJson으로 변환하여 업데이트
      final updatedUser = UserModel.fromJson(userData);
      authProvider.updateUser(updatedUser);

      if (mounted) {
        context.go('/map');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('온보딩 완료 실패: $e')),
        );
      }
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
              '추가 정보를 입력해주세요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // 메뉴 도전 강도
            const Text('메뉴 도전 강도'),
            ...AdventureLevel.values.map((level) => RadioListTile<AdventureLevel>(
              title: Text(level.displayName),
              value: level,
              groupValue: _challengeLevel,
              onChanged: (value) {
                setState(() {
                  _challengeLevel = value;
                });
              },
            )),
            const SizedBox(height: 20),
            // 한식 경험
            const Text('한식 경험'),
            ...KoreanExperience.values.map((exp) => RadioListTile<KoreanExperience>(
              title: Text(exp.displayName),
              value: exp,
              groupValue: _kfoodLevel,
              onChanged: (value) {
                setState(() {
                  _kfoodLevel = value;
                });
              },
            )),
            const Spacer(),
            if (_challengeLevel != null && _kfoodLevel != null)
              const Text(
                '환영합니다!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _challengeLevel == null || _kfoodLevel == null
                  ? null
                  : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Enter'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

