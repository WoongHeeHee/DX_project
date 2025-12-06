import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/responsive_helper.dart';
import '../../core/widgets/responsive_padding.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    // 일단 로그인 시도 없이 바로 온보딩 화면으로 이동
    context.go('/onboarding/language');
    
    // TODO: 실제 로그인 기능 구현 시 아래 코드 사용
    /*
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (success) {
        // 로그인 성공 시 온보딩 첫 화면으로 이동
        context.go('/onboarding/language');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? '로그인에 실패했습니다.'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        // 에러가 발생해도 온보딩 화면으로 이동
        context.go('/onboarding/language');
      }
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ResponsivePadding(
                child: Column(
                  children: [
                    // 로고를 중앙에 배치
                    Expanded(
                      child: Center(
                        child: _buildLogoPlaceholder(responsive),
                      ),
                    ),
                    // Google 로그인 버튼
                    _buildGoogleLoginButton(responsive, textTheme),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 10),
                    ),
                    // 영업 중 제보하기 버튼
                    _buildReportButton(responsive, textTheme),
                    SizedBox(
                      height: responsive.responsivePadding(mobilePadding: 40),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(ResponsiveHelper responsive) {
    final logoSize = responsive.responsiveFontSize(mobileSize: 120);
    
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          "로고 들어갈 예정",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: responsive.responsiveFontSize(mobileSize: 12),
            color: AppColors.inactiveText,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleLoginButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: _handleGoogleSignIn,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: responsive.responsivePadding(mobilePadding: 16),
          right: responsive.responsivePadding(mobilePadding: 16),
          top: responsive.responsivePadding(mobilePadding: 16),
          bottom: responsive.responsivePadding(mobilePadding: 16),
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: AppColors.mainText,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Google 로고
            Image.asset(
              "assets/images/Google_logo.png",
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            SizedBox(
              width: responsive.responsivePadding(mobilePadding: 8),
            ),
            Flexible(
              child: Text(
                "Google 로그인",
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.responsiveFontSize(mobileSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(
    ResponsiveHelper responsive,
    TextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: () {
        context.go('/report/guide');
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: responsive.responsivePadding(mobilePadding: 16),
          right: responsive.responsivePadding(mobilePadding: 16),
          top: responsive.responsivePadding(mobilePadding: 16),
          bottom: responsive.responsivePadding(mobilePadding: 16),
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: AppColors.mainText,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "영업 중 제보하기",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: responsive.responsiveFontSize(mobileSize: 16),
            fontWeight: FontWeight.w600,
            color: AppColors.mainText,
          ),
        ),
      ),
    );
  }
}

