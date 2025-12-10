import "package:flutter/material.dart";
import "../theme/app_colors.dart";
import "../widgets/responsive_helper.dart";
import "../widgets/responsive_padding.dart";

/// 에러 화면 위젯
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? buttonText;

  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final defaultButtonText = _getDefaultButtonText(locale.languageCode);
    final responsive = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ResponsivePadding(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 에러 아이콘 (선택사항)
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(
                        height: responsive.responsivePadding(mobilePadding: 24),
                      ),
                      // 에러 메시지
                      Text(
                        message,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.mainText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 돌아가기 버튼
            ResponsivePadding(
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: onRetry ??
                      () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    animationDuration: Duration.zero,
                  ),
                  child: Text(
                    buttonText ?? defaultButtonText,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: responsive.responsivePadding(mobilePadding: 40),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultButtonText(String locale) {
    switch (locale) {
      case 'en':
        return 'Go Back';
      case 'zh':
        return '返回';
      case 'ja':
        return '戻る';
      default:
        return '돌아가기';
    }
  }
}

/// 인증 에러 화면 (특별한 메시지)
class AuthErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const AuthErrorScreen({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final message = _getAuthErrorMessage(locale.languageCode);
    final buttonText = _getButtonText(locale.languageCode);

    return ErrorScreen(
      message: message,
      buttonText: buttonText,
      onRetry: onRetry ?? () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }

  String _getAuthErrorMessage(String locale) {
    switch (locale) {
      case 'en':
        return 'An authentication problem occurred. Returning to the initial screen.';
      case 'zh':
        return '发生身份验证问题。返回初始屏幕。';
      case 'ja':
        return '認証に問題が発生しました。初期画面に戻ります。';
      default:
        return '인증 문제가 발생했습니다. 초기화면으로 돌아갑니다.';
    }
  }

  String _getButtonText(String locale) {
    switch (locale) {
      case 'en':
        return 'Go Back';
      case 'zh':
        return '返回';
      case 'ja':
        return '戻る';
      default:
        return '돌아가기';
    }
  }
}

