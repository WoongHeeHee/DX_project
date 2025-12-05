import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class OnboardingNameGenerateScreen extends StatefulWidget {
  const OnboardingNameGenerateScreen({super.key});

  @override
  State<OnboardingNameGenerateScreen> createState() => _OnboardingNameGenerateScreenState();
}

class _OnboardingNameGenerateScreenState extends State<OnboardingNameGenerateScreen> {
  bool _isLoading = true;
  String? _koreanName;
  String? _englishPronunciation;
  String? _inputName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inputName == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra is String) {
        _inputName = extra;
        _generateKoreanName();
      }
    }
  }

  Future<void> _generateKoreanName() async {
    if (_inputName == null) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.post(
        '/users/generate-korean-name',
        data: {'input_name': _inputName},
      );

      final data = response.data as Map<String, dynamic>;
      setState(() {
        _koreanName = data['korean_name'] as String?;
        _englishPronunciation = data['english_pronunciation'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이름 생성 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('한국 이름 생성'),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text('Choosing a korean name just for...\n$_inputName'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_koreanName != null) ...[
                    Text(
                      '$_koreanName님',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    if (_englishPronunciation != null)
                      Text(
                        _englishPronunciation!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        // locale 정보도 함께 전달
                        context.push('/onboarding/main-1', extra: {
                          'locale': 'ko', // 실제로는 이전 화면에서 받은 locale 사용
                        });
                      },
                      child: const Text('다음'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

