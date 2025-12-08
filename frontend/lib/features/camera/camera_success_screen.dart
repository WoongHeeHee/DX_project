// lib/features/camera/camera_success_screen.dart

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../core/widgets/responsive_helper.dart";
import "../../core/theme/app_colors.dart";

class CameraSuccessScreen extends StatefulWidget {
  final String? returnPath;

  const CameraSuccessScreen({super.key, this.returnPath});

  @override
  State<CameraSuccessScreen> createState() => _CameraSuccessScreenState();
}

class _CameraSuccessScreenState extends State<CameraSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    // 2초 후 자동으로 이전 화면(또는 기본 경로)으로 이동
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final target = widget.returnPath ?? '/map';
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(target);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSuccessIcon(responsive),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 24),
                      ),
                      _buildSuccessMessage(responsive, textTheme),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(ResponsiveHelper responsive) {
    return Container(
      width: responsive.isMobile ? 120 : 140,
      height: responsive.isMobile ? 120 : 140,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle,
        size: responsive.isMobile ? 80 : 100,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildSuccessMessage(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    final messages = [
      "완벽한 사진이에요! 📸",
      "멋진 순간을 담았네요! ✨",
      "훌륭한 촬영입니다! 🎉",
      "사진이 정말 좋아요! 🌟",
    ];

    // 랜덤하게 메시지 선택 (간단하게 시간 기반으로)
    final messageIndex =
        DateTime.now().millisecondsSinceEpoch % messages.length;
    final message = messages[messageIndex];

    return Text(
      message,
      textAlign: TextAlign.center,
      style: textTheme.titleLarge?.copyWith(
        fontSize: responsive.responsiveFontSize(mobileSize: 24),
        fontWeight: FontWeight.w600,
        color: AppColors.mainText,
      ),
    );
  }
}

