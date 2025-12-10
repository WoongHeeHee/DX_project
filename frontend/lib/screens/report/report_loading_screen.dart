import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/theme/app_colors.dart";

class ReportLoadingScreen extends StatefulWidget {
  const ReportLoadingScreen({super.key});

  @override
  State<ReportLoadingScreen> createState() => _ReportLoadingScreenState();
}

class _ReportLoadingScreenState extends State<ReportLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 모델 판별 시간 벌기 (3초 후 shop-select 화면으로 이동)
    if (!_hasNavigated) {
      _hasNavigated = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          final extra = GoRouterState.of(context).extra;
          context.pushReplacement("/report/shop-select", extra: extra);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: 0.3 + (_animation.value * 0.7),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

