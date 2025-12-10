import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/theme/app_colors.dart";

class ReportCompleteScreen extends StatefulWidget {
  const ReportCompleteScreen({super.key});

  @override
  State<ReportCompleteScreen> createState() => _ReportCompleteScreenState();
}

class _ReportCompleteScreenState extends State<ReportCompleteScreen> {
  bool _hasNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 3초 후 로그인 화면으로 이동
    if (!_hasNavigated) {
      _hasNavigated = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.go("/login");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Image.asset(
          "assets/designs/images/thankyou.png",
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text("이미지를 불러올 수 없습니다");
          },
        ),
      ),
    );
  }
}

