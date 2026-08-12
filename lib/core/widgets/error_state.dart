import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'animated_page.dart';
import 'premium_button.dart';

/// Turns any thrown object into a short, user-facing message.
///
/// Screens should pass the caught error here rather than printing
/// `DioException: 500 …` at the user.
class AppErrorMessage {
  const AppErrorMessage._();

  static const String genericTitle = 'Something went wrong';
  static const String genericBody =
      "We couldn't complete your request. Please try again.";

  static const String offlineTitle = 'No internet connection';
  static const String offlineBody =
      'Check your network and try again.';

  static const String timeoutTitle = 'Taking too long';
  static const String timeoutBody =
      'The server is slow to respond. Please try again in a moment.';

  static const String serverTitle = 'Server is busy';
  static const String serverBody =
      "We're having trouble reaching HappyWedz right now. Please try again shortly.";

  static bool _isOffline(Object? error) {
    if (error is SocketException) return true;
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused') ||
        text.contains('connection closed') ||
        text.contains('no address associated');
  }

  static bool _isTimeout(Object? error) {
    final text = error.toString().toLowerCase();
    return error is HttpException && text.contains('timeout') ||
        text.contains('timeoutexception') ||
        text.contains('timeout');
  }

  static bool _isServer(Object? error) {
    final text = error.toString();
    return RegExp(r'\b5\d{2}\b').hasMatch(text);
  }

  /// Short headline for the given error.
  static String titleFor(Object? error) {
    if (error == null) return genericTitle;
    if (_isOffline(error)) return offlineTitle;
    if (_isTimeout(error)) return timeoutTitle;
    if (_isServer(error)) return serverTitle;
    return genericTitle;
  }

  /// One-line explanation for the given error.
  static String bodyFor(Object? error) {
    if (error == null) return genericBody;
    if (_isOffline(error)) return offlineBody;
    if (_isTimeout(error)) return timeoutBody;
    if (_isServer(error)) return serverBody;
    return genericBody;
  }

  static IconData iconFor(Object? error) {
    if (error != null && _isOffline(error)) return Icons.wifi_off_rounded;
    if (error != null && _isTimeout(error)) return Icons.hourglass_empty_rounded;
    return Icons.error_outline_rounded;
  }
}

/// Full-area error view with a retry action.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.error,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.compact = false,
    this.padding,
  });

  /// Raw error object. Used to derive a friendly title/message when [title] or
  /// [message] are not supplied. It is never rendered directly.
  final Object? error;

  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final double badge = compact ? 72 : 96;
    final resolvedIcon = icon ?? AppErrorMessage.iconFor(error);

    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: compact ? AppSpacing.xl : AppSpacing.xxxl,
            ),
        child: FadeSlideIn(
          duration: AppMotion.slow,
          offset: const Offset(0, 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.08),
                ),
                child: Icon(
                  resolvedIcon,
                  size: badge * 0.42,
                  color: AppColors.error.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
              Text(
                title ?? AppErrorMessage.titleFor(error),
                textAlign: TextAlign.center,
                style: compact ? AppText.cardTitle : AppText.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message ?? AppErrorMessage.bodyFor(error),
                textAlign: TextAlign.center,
                style: AppText.bodySm,
              ),
              if (onRetry != null) ...[
                SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
                PremiumButton.outlined(
                  label: retryLabel,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  size: PremiumButtonSize.medium,
                  expanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
